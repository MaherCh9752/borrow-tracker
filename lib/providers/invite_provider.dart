import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pending_invite_model.dart';
import '../services/invite_service.dart';
import '../services/shared_entry_service.dart';

/// Manages pending invites created by the current user for users
/// who haven't registered yet.
class InviteProvider extends ChangeNotifier {
  final InviteService _inviteService = InviteService();
  final SharedEntryService _sharedEntryService = SharedEntryService();
  StreamSubscription? _subscription;

  List<PendingInvite> _invites = [];
  bool _isLoading = false;
  String? _error;

  List<PendingInvite> get invites => _invites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Invites created by the current user that are still active (pending and
  /// not expired) — these show up before the invited user registers.
  List<PendingInvite> get pendingInvites =>
      _invites.where((i) => i.isPending).toList();

  void listenToInvites(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _inviteService.fetchInvites(userId).listen(
      (invites) {
        _invites = invites;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[InviteProvider] listenToInvites: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Cancels a pending invite. Also removes the linked entry, since it is
  /// awaiting a user who will no longer be invited.
  Future<bool> cancelInvite({required PendingInvite invite}) async {
    try {
      await _inviteService.deleteInvite(invite.inviteId);
      if (invite.entryId != null && invite.entryId!.isNotEmpty) {
        await _sharedEntryService.deleteEntry(entryId: invite.entryId!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[InviteProvider] cancelInvite: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
