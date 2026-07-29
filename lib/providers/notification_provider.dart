import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/borrow_lend.dart';
import '../models/reminder_settings.dart';
import '../models/shared_entry_model.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  ReminderSettings _settings = const ReminderSettings();
  bool _initialized = false;
  String? _userId;
  List<BorrowLend> _entries = [];
  List<_PendingNotification> _pending = [];
  Timer? _timer;
  bool _firingNow = false;

  ReminderSettings get settings => _settings;
  bool get isInitialized => _initialized;
  bool get hasCompletedSetup => _settings.setupCompleted;
  bool get notificationsEnabled => _settings.notificationsEnabled;

  Future<void> initialize(String userId) async {
    // Clear previous user's data and cancel their scheduled notifications
    _pending = [];
    _entries = [];
    await _notificationService.cancelAll();

    _userId = userId;
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('[Notifications] Plugin init failed: $e');
    }
    await _loadSettings();
    await _applyBootPrefs();
    _ensureTimer();
    _initialized = true;
    // _entries was cleared above — _scheduleAll will fire only after
    // onEntriesUpdated delivers this user's data from Firestore.
    notifyListeners();
  }

  Future<void> _applyBootPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledFromBoot =
          prefs.getBool('notification_enabled_from_boot') ?? false;
      if (enabledFromBoot && !_settings.notificationsEnabled) {
        _settings = _settings.copyWith(
          notificationsEnabled: true,
          setupCompleted: true,
        );
        await _saveSettings();
      }
      await prefs.remove('notification_enabled_from_boot');
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    // Load from local cache first (always — survives Firestore failures)
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('cached_reminder_settings');
      if (json != null) {
        _settings = ReminderSettings.fromMap(
          Map<String, dynamic>.from(jsonDecode(json)),
        );
        debugPrint(
          '[Notifications] Loaded from cache: enabled=${_settings.notificationsEnabled}',
        );
      }
    } catch (_) {}

    // Then sync from Firestore (updates cache if successful)
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['reminderSettings'] != null) {
          _settings = ReminderSettings.fromMap(
            Map<String, dynamic>.from(data['reminderSettings']),
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_reminder_settings',
            jsonEncode(_settings.toMap()),
          );
          debugPrint(
            '[Notifications] Synced from Firestore: enabled=${_settings.notificationsEnabled}',
          );
        }
      }
    } catch (e) {
      debugPrint('[Notifications] Firestore sync failed: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .set({'reminderSettings': _settings.toMap()}, SetOptions(merge: true))
          .timeout(const Duration(milliseconds: 500));

      // Cache locally for offline/fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_reminder_settings',
        jsonEncode(_settings.toMap()),
      );
    } catch (e) {
      // On timeout, settings are still cached locally.
      debugPrint('[Notifications] _saveSettings: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_reminder_settings',
          jsonEncode(_settings.toMap()),
        );
      } catch (_) {}
    }
  }

  Future<void> updateSettings(ReminderSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _saveSettings();
    try {
      if (_settings.notificationsEnabled && _entries.isNotEmpty) {
        await _scheduleAll(_entries);
      } else {
        await _notificationService.cancelAll();
      }
    } catch (e) {
      debugPrint('[Notifications] Scheduling error: $e');
    }
  }

  Future<void> completeSetup() async {
    _settings = _settings.copyWith(setupCompleted: true);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> requestNotificationPermissions() async {
    await _notificationService.requestPermissions();
    _settings = _settings.copyWith(notificationsEnabled: true);
    notifyListeners();
    await _saveSettings();
  }

  /// Called when entries change to reschedule all notifications.
  Future<void> onEntriesUpdated(List<BorrowLend> entries) async {
    _entries = entries;
    if (!_initialized || !_settings.notificationsEnabled) return;
    // Replace rather than cancel-then-schedule.
    await _scheduleAll(entries);
  }

  int _notificationId(String entryId, int offset) {
    return (entryId.hashCode.abs() % 100000) + offset;
  }

  void _ensureTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fireDue());
  }

  Future<void> _fireDue() async {
    if (_firingNow) return;
    _firingNow = true;
    try {
      if (!_settings.notificationsEnabled || _pending.isEmpty) return;
      final now = DateTime.now();
      final due = _pending.where((n) => !n.firedAt.isAfter(now)).toList();
      if (due.isEmpty) return;
      _pending.removeWhere((n) => due.contains(n));
      for (int i = 0; i < due.length; i++) {
        final n = due[i];
        debugPrint(
          '[Notifications] Firing now (${i + 1}/${due.length}): '
          '${n.title} - ${n.body}',
        );
        try {
          await _notificationService.showNotification(
            id: n.id,
            title: n.title,
            body: n.body,
          );
          await _notificationService.cancelScheduled(n.id);
        } catch (e) {
          debugPrint('[Notifications] Fire single notification error: $e');
        }
        if (i < due.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      debugPrint('[Notifications] _fireDue error: $e');
    } finally {
      _firingNow = false;
    }
  }

  Future<void> _scheduleAll(List<BorrowLend> entries) async {
    _pending = [];

    // Cancel stale alarms for entries that are now paid or have no deadline
    for (final entry in entries) {
      if (entry.status == EntryStatus.paid || entry.deadline == null) {
        for (final offset in [0, 1, 2]) {
          await _notificationService.cancel(_notificationId(entry.id, offset));
        }
      }
      if (entry is SharedEntry && entry.approvalStatus != ApprovalStatus.active) {
        for (final offset in [0, 1, 2]) {
          await _notificationService.cancel(_notificationId(entry.id, offset));
        }
      }
    }

    final now = DateTime.now();
    int scheduled = 0;

    for (final entry in entries) {
      if (entry.status == EntryStatus.paid || entry.deadline == null) continue;
      if (entry is SharedEntry && entry.approvalStatus != ApprovalStatus.active) continue;

      final deadline = entry.deadline!;
      final amountStr = '${entry.currency}${entry.amount.toStringAsFixed(2)}';
      final name = entry.personName;

      // Upcoming deadline reminder
      if (_settings.upcomingDeadlineReminders && deadline.isAfter(now)) {
        final reminderDate = deadline.subtract(
          Duration(days: _settings.reminderDaysBefore),
        );
        final base = _normalizeTime(reminderDate, now);
        final scheduledDate = _spreadTime(base, entry.id, 0);
        await _notificationService.scheduleOneTime(
          id: _notificationId(entry.id, 0),
          title: 'Upcoming Deadline',
          body:
              '$name - $amountStr is due in ${_settings.reminderDaysBefore} days',
          date: scheduledDate,
        );
        _pending.add(
          _PendingNotification(
            id: _notificationId(entry.id, 0),
            title: 'Upcoming Deadline',
            body:
                '$name - $amountStr is due in ${_settings.reminderDaysBefore} days',
            firedAt: scheduledDate,
          ),
        );
        debugPrint(
          '[Notifications] Upcoming: ${entry.personName} @ $scheduledDate',
        );
        scheduled++;
      }

      // Day-of-deadline reminder
      if (_settings.remindOnDayOfDeadline && deadline.isAfter(now)) {
        final base = _normalizeTime(deadline, now);
        final scheduledDate = _spreadTime(base, entry.id, 1);
        await _notificationService.scheduleOneTime(
          id: _notificationId(entry.id, 1),
          title: 'Deadline Today',
          body: '$name - $amountStr is due today!',
          date: scheduledDate,
        );
        _pending.add(
          _PendingNotification(
            id: _notificationId(entry.id, 1),
            title: 'Deadline Today',
            body: '$name - $amountStr is due today!',
            firedAt: scheduledDate,
          ),
        );
        debugPrint(
          '[Notifications] Due today: ${entry.personName} @ $scheduledDate',
        );
        scheduled++;
      }

      // Overdue reminders
      if (_settings.overdueReminders && deadline.isBefore(now)) {
        if (_settings.dailyOverdueReminder) {
          final base = _normalizeTime(now, now);
          final scheduledDate = _spreadTime(base, entry.id, 2);
          await _notificationService.scheduleDaily(
            id: _notificationId(entry.id, 2),
            title: 'Overdue Reminder',
            body:
                '$name - $amountStr was due on '
                '${deadline.day}/${deadline.month}/${deadline.year}',
            time: scheduledDate,
          );
          _pending.add(
            _PendingNotification(
              id: _notificationId(entry.id, 2),
              title: 'Overdue Reminder',
              body:
                  '$name - $amountStr was due on '
                  '${deadline.day}/${deadline.month}/${deadline.year}',
              firedAt: scheduledDate,
            ),
          );
          debugPrint(
            '[Notifications] Overdue daily: ${entry.personName} @ $scheduledDate',
          );
          scheduled++;
        } else {
          final base = _normalizeTime(
            now,
            now,
          ).add(const Duration(minutes: 30));
          final scheduledDate = _spreadTime(base, entry.id, 2);
          await _notificationService.scheduleOneTime(
            id: _notificationId(entry.id, 2),
            title: 'Overdue',
            body:
                '$name - $amountStr was due on '
                '${deadline.day}/${deadline.month}/${deadline.year}',
            date: scheduledDate,
          );
          _pending.add(
            _PendingNotification(
              id: _notificationId(entry.id, 2),
              title: 'Overdue',
              body:
                  '$name - $amountStr was due on '
                  '${deadline.day}/${deadline.month}/${deadline.year}',
              firedAt: scheduledDate,
            ),
          );
          debugPrint(
            '[Notifications] Overdue once: ${entry.personName} @ $scheduledDate',
          );
          scheduled++;
        }
      }
    }

    _ensureTimer();
    debugPrint('[Notifications] Done. $scheduled notifications scheduled.');
  }

  /// Spreads notifications within a window so simultaneous firings don't
  /// collide. Uses [entryId] and [offset] (notification type) to produce a
  /// deterministic per-notification delay (0–59 seconds).
  DateTime _spreadTime(DateTime base, String entryId, int offset) {
    final extra = (entryId.hashCode.abs() % 5) + (offset * 5);
    return base.add(Duration(seconds: extra));
  }

  DateTime _normalizeTime(DateTime date, DateTime now) {
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      _settings.reminderHour,
      _settings.reminderMinute,
    );
    final past = now.subtract(const Duration(seconds: 10));
    if (!scheduled.isAfter(past)) {
      return scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class _PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime firedAt;

  const _PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.firedAt,
  });
}
