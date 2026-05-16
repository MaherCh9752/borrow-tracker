import 'dart:async';
import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../services/entry_service.dart';

class EntryProvider extends ChangeNotifier {
  final EntryService _entryService = EntryService();
  StreamSubscription? _subscription;

  List<BorrowLend> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<BorrowLend> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEntries => _entries.isNotEmpty;

  double get totalBorrowed => _entries
      .where((e) => e.type == EntryType.borrow && e.status != EntryStatus.paid)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalLent => _entries
      .where((e) => e.type == EntryType.lend && e.status != EntryStatus.paid)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalBorrowedAll => _entries
      .where((e) => e.type == EntryType.borrow)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalLentAll => _entries
      .where((e) => e.type == EntryType.lend)
      .fold(0.0, (sum, e) => sum + e.amount);

  List<BorrowLend> get pendingEntries =>
      _entries.where((e) => e.status == EntryStatus.pending).toList();

  List<BorrowLend> get upcomingDeadlines {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return _entries
        .where((e) =>
            e.deadline != null &&
            e.deadline!.isAfter(now) &&
            e.deadline!.isBefore(weekFromNow) &&
            e.status != EntryStatus.paid)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  List<BorrowLend> get recentEntries {
    final sorted = List<BorrowLend>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  int get pendingCount => pendingEntries.length;
  int get upcomingDeadlineCount => upcomingDeadlines.length;

  /// Starts listening to entries for the given [userId].
  void listenToEntries(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _entryService.fetchEntries(userId).listen(
      (entries) {
        _entries = entries;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Creates a new entry.
  Future<bool> addEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    try {
      await _entryService.addEntry(userId: userId, entry: entry);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing entry.
  Future<bool> editEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    try {
      await _entryService.editEntry(userId: userId, entry: entry);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Deletes an entry by ID.
  Future<bool> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      await _entryService.deleteEntry(userId: userId, entryId: entryId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
