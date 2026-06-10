import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/borrow_lend.dart';

/// Generates PDF documents from borrow/lend entries.
class PdfService {
  /// Builds a PDF document containing all entries in a clean table format.
  Future<pw.Document> generateEntryReport(List<BorrowLend> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          if (entries.isEmpty)
            pw.Center(
              child: pw.Text(
                'No entries to display.',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
              ),
            )
          else
            _buildTable(entries),
          pw.SizedBox(height: 20),
          _buildSummary(entries),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader() {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Borrow Tracker',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo,
            ),
          ),
          pw.Text(
            'Exported on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildTable(List<BorrowLend> entries) {
    final headers = ['#', 'Person', 'Type', 'Amount', 'Currency', 'Status', 'Date', 'Deadline', 'Notes'];

    final data = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return [
        '${i + 1}',
        e.personName,
        e.type == EntryType.borrow ? 'Borrowed' : 'Lent',
        e.amount.toStringAsFixed(3),
        e.currency,
        e.status.name[0].toUpperCase() + e.status.name.substring(1),
        '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
        e.deadline != null
            ? '${e.deadline!.day}/${e.deadline!.month}/${e.deadline!.year}'
            : '-',
        e.notes ?? '-',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.indigo,
      ),
      headerAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(1.2),
        8: const pw.FlexColumnWidth(2),
      },
    );
  }

  pw.Widget _buildSummary(List<BorrowLend> entries) {
    final totalBorrowed = entries
        .where((e) => e.type == EntryType.borrow)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalLent = entries
        .where((e) => e.type == EntryType.lend)
        .fold(0.0, (sum, e) => sum + e.amount);
    final pendingCount = entries.where((e) => e.status == EntryStatus.pending).length;
    final paidCount = entries.where((e) => e.status == EntryStatus.paid).length;

    final primaryCurrency = 'TND';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _summaryItem('Total Entries', '${entries.length}'),
              _summaryItem('Total Borrowed', '$primaryCurrency ${totalBorrowed.toStringAsFixed(3)}'),
              _summaryItem('Total Lent', '$primaryCurrency ${totalLent.toStringAsFixed(3)}'),
              _summaryItem('Pending', '$pendingCount'),
              _summaryItem('Paid', '$paidCount'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
