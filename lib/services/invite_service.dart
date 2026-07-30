import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pending_invite_model.dart';
import '../utils/constants.dart';

/// Service for managing pending user invitations in Firestore.
class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new pending invite and returns it.
  /// [token] is a long random string for internal verification.
  /// [inviteCode] is a short human-readable code (e.g. ABC123).
  Future<PendingInvite> createInvite({
    required String createdBy,
    required String targetPersonName,
    String? entryId,
  }) async {
    final token = _generateToken(32);
    final inviteCode = _generateInviteCode(6);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final docRef = _firestore
        .collection(AppConstants.pendingInvitesCollection)
        .doc();

    final invite = PendingInvite(
      inviteId: docRef.id,
      token: token,
      inviteCode: inviteCode,
      createdBy: createdBy,
      targetPersonName: targetPersonName,
      status: 'pending',
      createdAt: now,
      expiresAt: expiresAt,
      entryId: entryId,
    );

    await docRef.set(invite.toMap());
    return invite;
  }

  /// Updates an invite with the entry ID after the entry is saved.
  Future<void> updateInviteEntryId({
    required String inviteId,
    required String entryId,
  }) async {
    await _firestore
        .collection(AppConstants.pendingInvitesCollection)
        .doc(inviteId)
        .update({'entryId': entryId});
  }

  /// Looks up an invite by its short [inviteCode].
  Future<PendingInvite?> lookupByCode(String inviteCode) async {
    final snapshot = await _firestore
        .collection(AppConstants.pendingInvitesCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final invite = PendingInvite.fromMap(doc.id, doc.data());
    return invite.isExpired ? null : invite;
  }

  /// Marks an invite as accepted.
  Future<void> acceptInvite(String inviteId) async {
    await _firestore
        .collection(AppConstants.pendingInvitesCollection)
        .doc(inviteId)
        .update({'status': 'accepted'});
  }

  /// Processes an invite after a new user signs up:
  /// 1. Re-fetches the invite from Firestore (to get the latest entryId)
  /// 2. Accepts the invite
  /// 3. Links the new user to the shared entry using FieldValue.arrayUnion
  ///    (no read needed, so the new user doesn't need to be a participant yet)
  Future<void> processInviteAfterSignup({
    required PendingInvite invite,
    required String newUserId,
    required String newUserDisplayName,
  }) async {
    // Re-fetch the invite from Firestore to get the latest entryId,
    // which may have been set after the user verified their invite code
    // on the signup screen.
    final freshDoc = await _firestore
        .collection(AppConstants.pendingInvitesCollection)
        .doc(invite.inviteId)
        .get();

    String? entryId;
    if (freshDoc.exists) {
      entryId = freshDoc.data()?['entryId'] as String?;
    }

    await acceptInvite(invite.inviteId);

    if (entryId == null || entryId.isEmpty) return;

    // Use FieldValue.arrayUnion to add the new user to participants without
    // needing to read the current list first (the new user isn't a participant
    // yet, so a read would be denied by Firestore rules).
    final entryRef = _firestore
        .collection(AppConstants.sharedEntriesCollection)
        .doc(entryId);

    await entryRef.update({
      'participants': FieldValue.arrayUnion([newUserId]),
      'linkedUserId': newUserId,
      'linkedUserName': newUserDisplayName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Generates a cryptographically random alphanumeric [length]-char token.
  String _generateToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Generates a short uppercase invite code (e.g. A1B2C3).
  String _generateInviteCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
