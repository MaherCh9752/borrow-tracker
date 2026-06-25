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
    );

    await docRef.set(invite.toMap());
    return invite;
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
