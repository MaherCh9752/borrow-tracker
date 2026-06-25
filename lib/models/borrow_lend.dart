enum EntryType { borrow, lend }

enum EntryStatus { pending, paid, partial }

enum ApprovalStatus { pendingApproval, active, rejected }

class BorrowLend {
  final String id;
  final String personName;
  final double amount;
  final String currency;
  final EntryType type;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deadline;
  final EntryStatus status;

  BorrowLend({
    required this.id,
    required this.personName,
    required this.amount,
    this.currency = 'USD',
    required this.type,
    this.notes,
    required this.createdAt,
    this.deadline,
    this.status = EntryStatus.pending,
  });

  BorrowLend copyWith({
    String? id,
    String? personName,
    double? amount,
    String? currency,
    EntryType? type,
    String? notes,
    DateTime? createdAt,
    DateTime? deadline,
    EntryStatus? status,
  }) {
    return BorrowLend(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }

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
    };
  }

  factory BorrowLend.fromMap(Map<String, dynamic> map) {
    return BorrowLend(
      id: map['id'] ?? '',
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      type: _parseEntryType(map['type']),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'])
          : null,
      status: _parseEntryStatus(map['status']),
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
}
