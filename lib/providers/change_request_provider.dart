import 'dart:async';
import 'package:flutter/material.dart';
import '../models/change_request.dart';
import '../models/shared_entry_model.dart';
import '../services/change_request_service.dart';
import '../services/shared_entry_service.dart';

class ChangeRequestProvider extends ChangeNotifier {
  final ChangeRequestService _changeRequestService = ChangeRequestService();
  final SharedEntryService _sharedEntryService = SharedEntryService();
  StreamSubscription? _subscription;

  List<ChangeRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  String _currentUserId = '';

  List<ChangeRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Change requests that the current user needs to approve (others edited entries linked to me).
  List<ChangeRequest> get incomingRequests => _requests
      .where((r) => r.linkedUserId == _currentUserId && r.requestedBy != _currentUserId)
      .toList();

  /// Change requests that the current user created (waiting for the other user).
  List<ChangeRequest> get outgoingRequests => _requests
      .where((r) => r.requestedBy == _currentUserId)
      .toList();

  /// Total pending count for badge (incoming only — things I need to act on).
  int get pendingCount => incomingRequests.length;

  void listenToChangeRequests(String userId) {
    _subscription?.cancel();
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription = _changeRequestService.fetchChangeRequests(userId).listen(
      (requests) {
        _requests = requests;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ChangeRequestProvider] listenToChangeRequests: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create a change request for an edited entry.
  Future<bool> createChangeRequest({
    required SharedEntry currentEntry,
    required Map<String, dynamic> proposedChanges,
    required String requestedByName,
  }) async {
    try {
      // Determine the correct approver:
      // - If the creator is editing → the linked user approves
      // - If the linked user is editing → the creator approves
      final isCreator = _currentUserId == currentEntry.createdBy;
      final approverUserId = isCreator
          ? (currentEntry.linkedUserId ?? currentEntry.createdBy)
          : currentEntry.createdBy;
      final approverUserName = isCreator
          ? (currentEntry.linkedUserName ?? currentEntry.createdByName)
          : currentEntry.createdByName;

      final request = ChangeRequest(
        id: '',
        entryId: currentEntry.id,
        requestedBy: _currentUserId,
        requestedByName: requestedByName,
        linkedUserId: approverUserId,
        linkedUserName: approverUserName ?? '',
        participants: [
          _currentUserId,
          if (currentEntry.linkedUserId != null &&
              currentEntry.linkedUserId != _currentUserId)
            currentEntry.linkedUserId!,
          if (currentEntry.createdBy != _currentUserId &&
              currentEntry.createdBy != currentEntry.linkedUserId)
            currentEntry.createdBy,
        ],
        proposedChanges: proposedChanges,
        status: ChangeRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _changeRequestService.createRequest(request: request);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChangeRequestProvider] createChangeRequest: $e');
      return false;
    }
  }

  /// Accept a change request — apply proposed changes to the entry.
  Future<bool> acceptRequest({required ChangeRequest request}) async {
    try {
      // Apply changes to the entry
      final entryMap = request.proposedChanges;
      entryMap['updatedAt'] = DateTime.now().toIso8601String();

      await _sharedEntryService.editEntryFromMap(
        entryId: request.entryId,
        data: entryMap,
      );

      // Mark the request as accepted
      await _changeRequestService.updateStatus(
        requestId: request.id,
        status: ChangeRequestStatus.accepted,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChangeRequestProvider] acceptRequest: $e');
      return false;
    }
  }

  /// Reject a change request — entry remains unchanged.
  Future<bool> rejectRequest({required ChangeRequest request}) async {
    try {
      await _changeRequestService.updateStatus(
        requestId: request.id,
        status: ChangeRequestStatus.rejected,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChangeRequestProvider] rejectRequest: $e');
      return false;
    }
  }

  /// Cancel a change request (by the requester).
  Future<bool> cancelRequest({required ChangeRequest request}) async {
    try {
      await _changeRequestService.updateStatus(
        requestId: request.id,
        status: ChangeRequestStatus.rejected,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ChangeRequestProvider] cancelRequest: $e');
      return false;
    }
  }

  /// Delete all change requests for a given entry (used when entry is deleted).
  Future<void> deleteRequestsForEntry({required String entryId}) async {
    try {
      await _changeRequestService.deleteRequestsForEntry(entryId: entryId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChangeRequestProvider] deleteRequestsForEntry: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
