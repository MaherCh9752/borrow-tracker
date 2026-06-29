import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';

enum ChangeRequestStatus { pending, accepted, rejected }

class ChangeRequest {
  final String id;
  final String entryId;
  final String requestedBy;
  final String requestedByName;
  final String linkedUserId;
  final String linkedUserName;
  final List<String> participants;
  final Map<String, dynamic> proposedChanges;
  final ChangeRequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ChangeRequest({
    required this.id,
    required this.entryId,
    required this.requestedBy,
    required this.requestedByName,
    required this.linkedUserId,
    required this.linkedUserName,
    required this.participants,
    required this.proposedChanges,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  ChangeRequest copyWith({
    String? id,
    String? entryId,
    String? requestedBy,
    String? requestedByName,
    String? linkedUserId,
    String? linkedUserName,
    List<String>? participants,
    Map<String, dynamic>? proposedChanges,
    ChangeRequestStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return ChangeRequest(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      linkedUserName: linkedUserName ?? this.linkedUserName,
      participants: participants ?? this.participants,
      proposedChanges: proposedChanges ?? this.proposedChanges,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'linkedUserId': linkedUserId,
      'linkedUserName': linkedUserName,
      'participants': participants,
      'proposedChanges': proposedChanges,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory ChangeRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    return ChangeRequest(
      id: id ?? map['id'] ?? '',
      entryId: map['entryId'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      requestedByName: map['requestedByName'] ?? '',
      linkedUserId: map['linkedUserId'] ?? '',
      linkedUserName: map['linkedUserName'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      proposedChanges: Map<String, dynamic>.from(map['proposedChanges'] ?? {}),
      status: ChangeRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChangeRequestStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'])
          : null,
    );
  }

  /// Get a description of what changed between the current entry and proposed changes.
  List<String> describeChanges(SharedEntry currentEntry) {
    final changes = <String>[];
    final proposed = proposedChanges;

    if (proposed['amount'] != null &&
        (proposed['amount'] as num).toDouble() != currentEntry.amount) {
      changes.add(
          'Amount: ${currentEntry.amount.toStringAsFixed(3)} → ${(proposed['amount'] as num).toStringAsFixed(3)}');
    }
    if (proposed['type'] != null && proposed['type'] != currentEntry.type.name) {
      final currentType = currentEntry.type == EntryType.borrow
          ? 'Borrowed'
          : 'Lent';
      final newType =
          proposed['type'] == 'borrow' ? 'Borrowed' : 'Lent';
      changes.add('Type: $currentType → $newType');
    }
    if (proposed['currency'] != null &&
        proposed['currency'] != currentEntry.currency) {
      changes.add('Currency: ${currentEntry.currency} → ${proposed['currency']}');
    }
    if (proposed['status'] != null &&
        proposed['status'] != currentEntry.status.name) {
      changes.add(
          'Status: ${currentEntry.status.name} → ${proposed['status']}');
    }
    if (proposed['deadline'] != currentEntry.deadline?.toIso8601String()) {
      final currentDeadline =
          currentEntry.deadline != null ? _formatDate(currentEntry.deadline!) : 'None';
      final newDeadline = proposed['deadline'] != null
          ? _formatDate(DateTime.parse(proposed['deadline']))
          : 'None';
      changes.add('Deadline: $currentDeadline → $newDeadline');
    }
    if (proposed['notes'] != currentEntry.notes) {
      final currentNotes =
          currentEntry.notes != null && currentEntry.notes!.isNotEmpty
              ? currentEntry.notes!
              : 'None';
      final newNotes = proposed['notes'] != null &&
              (proposed['notes'] as String).isNotEmpty
          ? proposed['notes'] as String
          : 'None';
      changes.add('Notes: "$currentNotes" → "$newNotes"');
    }
    if (proposed['personName'] != null &&
        proposed['personName'] != currentEntry.personName) {
      changes.add(
          'Person: ${currentEntry.personName} → ${proposed['personName']}');
    }

    return changes;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
