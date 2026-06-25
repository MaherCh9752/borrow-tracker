import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pending invitation for a user who hasn't registered yet.
class PendingInvite {
  final String inviteId;
  final String token;
  final String inviteCode;
  final String createdBy;
  final String targetPersonName;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  PendingInvite({
    required this.inviteId,
    required this.token,
    required this.inviteCode,
    required this.createdBy,
    required this.targetPersonName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Whether the invite has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the invite is still pending (not accepted or expired).
  bool get isPending => status == 'pending' && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'targetPersonName': targetPersonName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory PendingInvite.fromMap(String id, Map<String, dynamic> map) {
    return PendingInvite(
      inviteId: id,
      token: map['token'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      targetPersonName: map['targetPersonName'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }
}
