import 'dart:async';
import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../services/entry_service.dart';

enum DeadlineFilter { all, hasDeadline, noDeadline, overdue, upcoming }

class EntryProvider extends ChangeNotifier {
  final EntryService _entryService = EntryService();
  StreamSubscription? _subscription;

  void Function()? onEntriesRefreshed;

  List<BorrowLend> _entries = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  EntryStatus? _statusFilter;
  EntryType? _typeFilter;
  String? _currencyFilter;
  DeadlineFilter _deadlineFilter = DeadlineFilter.all;
  bool _filtersActive = false;
  int _activeFilterCount = 0;

  List<BorrowLend> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEntries => _entries.isNotEmpty;

  String get searchQuery => _searchQuery;
  EntryStatus? get statusFilter => _statusFilter;
  EntryType? get typeFilter => _typeFilter;
  String? get currencyFilter => _currencyFilter;
  DeadlineFilter get deadlineFilter => _deadlineFilter;
  bool get filtersActive => _filtersActive;
  int get activeFilterCount => _activeFilterCount;

  List<BorrowLend> get filteredEntries {
    var result = _entries.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((e) => e.personName.toLowerCase().contains(query))
          .toList();
    }

    if (_statusFilter != null) {
      result = result.where((e) => e.status == _statusFilter).toList();
    }

    if (_typeFilter != null) {
      result = result.where((e) => e.type == _typeFilter).toList();
    }

    if (_currencyFilter != null) {
      result = result.where((e) => e.currency == _currencyFilter).toList();
    }

    switch (_deadlineFilter) {
      case DeadlineFilter.hasDeadline:
        result = result.where((e) => e.deadline != null).toList();
      case DeadlineFilter.noDeadline:
        result = result.where((e) => e.deadline == null).toList();
      case DeadlineFilter.overdue:
        final now = DateTime.now();
        result = result
            .where((e) =>
                e.deadline != null &&
                e.deadline!.isBefore(now) &&
                e.status != EntryStatus.paid)
            .toList();
      case DeadlineFilter.upcoming:
        final now = DateTime.now();
        final weekFromNow = now.add(const Duration(days: 7));
        result = result
            .where((e) =>
                e.deadline != null &&
                e.deadline!.isAfter(now) &&
                e.deadline!.isBefore(weekFromNow))
            .toList();
      case DeadlineFilter.all:
        break;
    }

    return result;
  }

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

  void setSearchQuery(String query) {
    _searchQuery = query;
    _recalcFilters();
    notifyListeners();
  }

  void setStatusFilter(EntryStatus? status) {
    _statusFilter = _statusFilter == status ? null : status;
    _recalcFilters();
    notifyListeners();
  }

  void setTypeFilter(EntryType? type) {
    _typeFilter = _typeFilter == type ? null : type;
    _recalcFilters();
    notifyListeners();
  }

  void setCurrencyFilter(String? currency) {
    _currencyFilter = _currencyFilter == currency ? null : currency;
    _recalcFilters();
    notifyListeners();
  }

  void setDeadlineFilter(DeadlineFilter filter) {
    _deadlineFilter = _deadlineFilter == filter ? DeadlineFilter.all : filter;
    _recalcFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _typeFilter = null;
    _currencyFilter = null;
    _deadlineFilter = DeadlineFilter.all;
    _recalcFilters();
    notifyListeners();
  }

  void _recalcFilters() {
    _activeFilterCount = 0;
    if (_statusFilter != null) _activeFilterCount++;
    if (_typeFilter != null) _activeFilterCount++;
    if (_currencyFilter != null) _activeFilterCount++;
    if (_deadlineFilter != DeadlineFilter.all) _activeFilterCount++;
    if (_searchQuery.isNotEmpty) _activeFilterCount++;
    _filtersActive = _activeFilterCount > 0;
  }

  Set<String> get usedCurrencies =>
      _entries.map((e) => e.currency).toSet();

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
        onEntriesRefreshed?.call();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    try {
      await _entryService.addEntry(userId: userId, entry: entry).timeout(
            const Duration(milliseconds: 500),
          );
      return true;
    } catch (e) {
      // On timeout, Firestore still queued the write locally.
      debugPrint('[EntryProvider] addEntry: $e');
      return true;
    }
  }

  Future<bool> editEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    try {
      await _entryService.editEntry(userId: userId, entry: entry).timeout(
            const Duration(milliseconds: 500),
          );
      return true;
    } catch (e) {
      debugPrint('[EntryProvider] editEntry: $e');
      return true;
    }
  }

  Future<bool> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      await _entryService
          .deleteEntry(userId: userId, entryId: entryId)
          .timeout(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('[EntryProvider] deleteEntry: $e');
      return true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    onEntriesRefreshed = null;
    super.dispose();
  }
}
