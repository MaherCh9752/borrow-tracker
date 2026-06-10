import 'package:csv/csv.dart';
import '../models/borrow_lend.dart';

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
  String generateCsv(List<BorrowLend> entries) {
    final rows = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return [
        i + 1,
        e.personName,
        e.type == EntryType.borrow ? 'Borrowed' : 'Lent',
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
  List<int> generateCsvBytes(List<BorrowLend> entries) {
    return generateCsv(entries).codeUnits;
  }
}
