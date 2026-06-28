import 'package:csv/csv.dart';
import '../models/borrow_lend.dart';
import '../models/shared_entry_model.dart';

/// Generates CSV data from borrow/lend entries.
class CsvService {
  static const List<String> _headers = [
    '#',
    'Person',
    'Type',
    'Amount',
    'Currency',
    'Status',
    'Date',
    'Deadline',
    'Notes',
  ];

  /// Converts [entries] to a CSV string with headers.
  /// If [currentUserId] is provided, entry type and person name are resolved
  /// from the current user's perspective.
  String generateCsv(List<BorrowLend> entries, {String? currentUserId}) {
    final rows = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;

      String personName = e.personName;
      String typeLabel;

      if (currentUserId != null && e is SharedEntry) {
        final isCreator = e.createdBy == currentUserId;
        personName = isCreator
            ? (e.linkedUserName ?? e.personName)
            : (e.createdByName ?? e.personName);
        typeLabel = e.entryTypeFor(currentUserId) == EntryType.borrow
            ? 'Borrowed'
            : 'Lent';
      } else {
        typeLabel = e.type == EntryType.borrow ? 'Borrowed' : 'Lent';
      }

      return [
        i + 1,
        personName,
        typeLabel,
        e.amount.toStringAsFixed(3),
        e.currency,
        e.status.name[0].toUpperCase() + e.status.name.substring(1),
        '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}',
        e.deadline != null
            ? '${e.deadline!.year}-${e.deadline!.month.toString().padLeft(2, '0')}-${e.deadline!.day.toString().padLeft(2, '0')}'
            : '',
        e.notes ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert(
      [_headers, ...rows],
    );
  }

  /// Returns the CSV as bytes for file saving.
  List<int> generateCsvBytes(List<BorrowLend> entries, {String? currentUserId}) {
    return generateCsv(entries, currentUserId: currentUserId).codeUnits;
  }
}
