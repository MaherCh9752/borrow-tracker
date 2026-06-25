import 'dart:async';
import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';
import '../services/shared_entry_service.dart';

enum SharedDeadlineFilter { all, hasDeadline, noDeadline, overdue, upcoming }

class SharedEntryProvider extends ChangeNotifier {
  final SharedEntryService _sharedEntryService = SharedEntryService();
  StreamSubscription? _subscription;

  void Function()? onEntriesRefreshed;

  List<SharedEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  String _currentUserId = '';

  String _searchQuery = '';
  EntryStatus? _statusFilter;
  EntryType? _typeFilter;
  String? _currencyFilter;
  SharedDeadlineFilter _deadlineFilter = SharedDeadlineFilter.all;
  bool _filtersActive = false;
  int _activeFilterCount = 0;

  List<SharedEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEntries => _entries.isNotEmpty;
  String get currentUserId => _currentUserId;

  /// Entries with approvalStatus == ACTIVE (excludes PENDING_APPROVAL and REJECTED).
  List<SharedEntry> get activeEntries => _entries
      .where((e) => e.approvalStatus == ApprovalStatus.active)
      .toList();

  /// Entries where the current user is the linked user and status is PENDING_APPROVAL.
  /// These need the current user's approval.
  List<SharedEntry> get pendingApprovals => _entries
      .where((e) =>
          e.linkedUserId == _currentUserId &&
          e.createdBy != _currentUserId &&
          e.approvalStatus == ApprovalStatus.pendingApproval)
      .toList();

  /// Entries created by the current user that are still PENDING_APPROVAL.
  /// These are waiting for the linked user to accept/reject.
  List<SharedEntry> get pendingFromMe => _entries
      .where((e) =>
          e.createdBy == _currentUserId &&
          e.linkedUserId != null &&
          e.approvalStatus == ApprovalStatus.pendingApproval)
      .toList();

  String get searchQuery => _searchQuery;
  EntryStatus? get statusFilter => _statusFilter;
  EntryType? get typeFilter => _typeFilter;
  String? get currencyFilter => _currencyFilter;
  SharedDeadlineFilter get deadlineFilter => _deadlineFilter;
  bool get filtersActive => _filtersActive;
  int get activeFilterCount => _activeFilterCount;

  List<SharedEntry> get filteredEntries {
    var result = activeEntries.toList();

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
      case SharedDeadlineFilter.hasDeadline:
        result = result.where((e) => e.deadline != null).toList();
      case SharedDeadlineFilter.noDeadline:
        result = result.where((e) => e.deadline == null).toList();
      case SharedDeadlineFilter.overdue:
        final now = DateTime.now();
        result = result
            .where((e) =>
                e.deadline != null &&
                e.deadline!.isBefore(now) &&
                e.status != EntryStatus.paid)
            .toList();
      case SharedDeadlineFilter.upcoming:
        final now = DateTime.now();
        final weekFromNow = now.add(const Duration(days: 7));
        result = result
            .where((e) =>
                e.deadline != null &&
                e.deadline!.isAfter(now) &&
                e.deadline!.isBefore(weekFromNow))
            .toList();
      case SharedDeadlineFilter.all:
        break;
    }

    return result;
  }

  double get totalBorrowed => activeEntries
      .where((e) =>
          e.entryTypeFor(_currentUserId) == EntryType.borrow &&
          e.status != EntryStatus.paid)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalLent => activeEntries
      .where((e) =>
          e.entryTypeFor(_currentUserId) == EntryType.lend &&
          e.status != EntryStatus.paid)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalBorrowedAll => activeEntries
      .where((e) => e.entryTypeFor(_currentUserId) == EntryType.borrow)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalLentAll => activeEntries
      .where((e) => e.entryTypeFor(_currentUserId) == EntryType.lend)
      .fold(0.0, (sum, e) => sum + e.amount);

  List<SharedEntry> get pendingEntries =>
      activeEntries.where((e) => e.status == EntryStatus.pending).toList();

  List<SharedEntry> get upcomingDeadlines {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return activeEntries
        .where((e) =>
            e.deadline != null &&
            e.deadline!.isAfter(now) &&
            e.deadline!.isBefore(weekFromNow) &&
            e.status != EntryStatus.paid)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  List<SharedEntry> get recentEntries {
    final sorted = List<SharedEntry>.from(activeEntries)
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

  void setDeadlineFilter(SharedDeadlineFilter filter) {
    _deadlineFilter =
        _deadlineFilter == filter ? SharedDeadlineFilter.all : filter;
    _recalcFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _typeFilter = null;
    _currencyFilter = null;
    _deadlineFilter = SharedDeadlineFilter.all;
    _recalcFilters();
    notifyListeners();
  }

  void _recalcFilters() {
    _activeFilterCount = 0;
    if (_statusFilter != null) _activeFilterCount++;
    if (_typeFilter != null) _activeFilterCount++;
    if (_currencyFilter != null) _activeFilterCount++;
    if (_deadlineFilter != SharedDeadlineFilter.all) _activeFilterCount++;
    if (_searchQuery.isNotEmpty) _activeFilterCount++;
    _filtersActive = _activeFilterCount > 0;
  }

  Set<String> get usedCurrencies => _entries.map((e) => e.currency).toSet();

  /// Starts listening to shared entries for the given [userId].
  void listenToEntries(String userId) {
    _subscription?.cancel();
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription = _sharedEntryService.fetchEntries(userId).listen(
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

  Future<bool> addEntry({required SharedEntry entry}) async {
    try {
      await _sharedEntryService.addEntry(entry: entry).timeout(
            const Duration(milliseconds: 500),
          );
      return true;
    } catch (e) {
      debugPrint('[SharedEntryProvider] addEntry: $e');
      return true;
    }
  }

  Future<bool> editEntry({required SharedEntry entry}) async {
    try {
      await _sharedEntryService.editEntry(entry: entry).timeout(
            const Duration(milliseconds: 500),
          );
      return true;
    } catch (e) {
      debugPrint('[SharedEntryProvider] editEntry: $e');
      return true;
    }
  }

  Future<bool> deleteEntry({required String entryId}) async {
    try {
      await _sharedEntryService
          .deleteEntry(entryId: entryId)
          .timeout(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('[SharedEntryProvider] deleteEntry: $e');
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
