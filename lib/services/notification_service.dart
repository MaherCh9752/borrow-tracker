import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return true;
  }

  NotificationDetails get _details {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final delay = date.difference(now);
    if (delay.isNegative || delay > const Duration(days: 365)) {
      print('[NotifSvc] Skipping one-time (delay=$delay): id=$id');
      return;
    }

    print('[NotifSvc] Registering one-time: id=$id delay=${delay.inSeconds}s');

    // Layer 1: WorkManager for background delivery
    await Workmanager().registerOneOffTask(
      'notif_$id',
      'showNotification',
      inputData: {
        'id': id,
        'title': title,
        'body': body,
      },
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Layer 2: Native AlarmManager (via flutter_local_notifications)
    // Fires even when the app is killed.
    await _zonedScheduleBackup(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    final now = DateTime.now();
    final firstFire = time.isAfter(now)
        ? time
        : DateTime(
            now.year, now.month, now.day,
            time.hour, time.minute, time.second,
          ).add(const Duration(days: 1));
    final firstDelay = firstFire.difference(now);

    if (firstDelay.isNegative || firstDelay > const Duration(days: 365)) {
      print('[NotifSvc] Skipping daily (firstDelay=$firstDelay): id=$id');
      return;
    }

    print('[NotifSvc] Registering daily: id=$id firstDelay=${firstDelay.inSeconds}s');

    // Layer 1: WorkManager periodic task for background delivery
    await Workmanager().registerPeriodicTask(
      'notif_${id}_daily',
      'showNotification',
      inputData: {
        'id': id,
        'title': title,
        'body': body,
      },
      initialDelay: firstDelay,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Layer 2: Native AlarmManager repeating alarm
    // Fires even when app is killed. DateTimeComponents.time makes
    // it repeat daily at the same wall-clock time.
    await _zonedScheduleBackup(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(firstFire, tz.local),
      repeatDaily: true,
    );
  }

  /// Schedules a native AlarmManager notification as a backup.
  /// Tries exact mode first (requires SCHEDULE_EXACT_ALARM), falls back
  /// to inexact (works without special permission, fires within ~10 min).
  Future<void> _zonedScheduleBackup({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    bool repeatDaily = false,
  }) async {
    final components = repeatDaily ? DateTimeComponents.time : null;

    // Try exact+allowWhileIdle (requires SCHEDULE_EXACT_ALARM on Android 12+)
    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          _details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: mode,
          matchDateTimeComponents: components,
        );
        print('[NotifSvc] zonedSchedule mode=$mode id=$id');
        return;
      } catch (e) {
        print('[NotifSvc] zonedSchedule mode=$mode failed: $e');
      }
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details);
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    await Workmanager().cancelByUniqueName('notif_$id');
    await Workmanager().cancelByUniqueName('notif_${id}_daily');
  }

  /// Cancels pending delivery (WorkManager + zonedSchedule alarm).
  /// Does NOT hide already-shown notifications.
  Future<void> cancelScheduled(int id) async {
    await Workmanager().cancelByUniqueName('notif_$id');
    await Workmanager().cancelByUniqueName('notif_${id}_daily');
  }

  Future<void> cancelAll() async {
    // Cancel all displayed notifications
    await _plugin.cancelAll();
    // Cancel all pending zonedSchedule alarms by iterating pending requests
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        await _plugin.cancel(req.id);
      }
    } catch (_) {}
    // Cancel all WorkManager tasks
    await Workmanager().cancelAll();
  }
}
