import 'borrow_lend.dart';

class SharedEntry extends BorrowLend {
  final String createdBy;
  final List<String> participants;
  final DateTime? updatedAt;
  final String? linkedUserId;
  final String? linkedUserName;
  final ApprovalStatus approvalStatus;

  SharedEntry({
    required super.id,
    required super.personName,
    required super.amount,
    super.currency = 'TND',
    required super.type,
    super.notes,
    required super.createdAt,
    super.deadline,
    super.status = EntryStatus.pending,
    required this.createdBy,
    required this.participants,
    this.updatedAt,
    this.linkedUserId,
    this.linkedUserName,
    this.approvalStatus = ApprovalStatus.pendingApproval,
  });

  @override
  SharedEntry copyWith({
    String? id,
    String? personName,
    double? amount,
    String? currency,
    EntryType? type,
    String? notes,
    DateTime? createdAt,
    DateTime? deadline,
    EntryStatus? status,
    String? createdBy,
    List<String>? participants,
    DateTime? updatedAt,
    String? linkedUserId,
    String? linkedUserName,
    ApprovalStatus? approvalStatus,
  }) {
    return SharedEntry(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      linkedUserName: linkedUserName ?? this.linkedUserName,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'personName': personName,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
      'createdBy': createdBy,
      'participants': participants,
      'updatedAt': DateTime.now().toIso8601String(),
      'linkedUserId': linkedUserId,
      'linkedUserName': linkedUserName,
      'approvalStatus': approvalStatus.name,
    };
  }

  factory SharedEntry.fromMap(Map<String, dynamic> map) {
    return SharedEntry(
      id: map['id'] ?? '',
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TND',
      type: _parseEntryType(map['type']),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'])
          : null,
      status: _parseEntryStatus(map['status']),
      createdBy: map['createdBy'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      linkedUserId: map['linkedUserId'],
      linkedUserName: map['linkedUserName'],
      approvalStatus: _parseApprovalStatus(map['approvalStatus']),
    );
  }

  static EntryType _parseEntryType(String? value) {
    switch (value) {
      case 'borrow':
        return EntryType.borrow;
      case 'lend':
        return EntryType.lend;
      default:
        return EntryType.borrow;
    }
  }

  static EntryStatus _parseEntryStatus(String? value) {
    switch (value) {
      case 'pending':
        return EntryStatus.pending;
      case 'paid':
        return EntryStatus.paid;
      case 'partial':
        return EntryStatus.partial;
      default:
        return EntryStatus.pending;
    }
  }

  static ApprovalStatus _parseApprovalStatus(String? value) {
    switch (value) {
      case 'pendingApproval':
        return ApprovalStatus.pendingApproval;
      case 'active':
        return ApprovalStatus.active;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pendingApproval;
    }
  }

  /// Returns the entry type from [userId]'s perspective.
  /// If the viewer is the linked user, borrow/lend is inverted.
  EntryType entryTypeFor(String userId) {
    if (linkedUserId != null && linkedUserId == userId) {
      return type == EntryType.borrow ? EntryType.lend : EntryType.borrow;
    }
    return type;
  }
}
