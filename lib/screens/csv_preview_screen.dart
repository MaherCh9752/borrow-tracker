import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../services/csv_service.dart';

/// Screen that previews CSV data and allows saving to a chosen location.
class CsvPreviewScreen extends StatefulWidget {
  final List<BorrowLend> entries;

  const CsvPreviewScreen({super.key, required this.entries});

  @override
  State<CsvPreviewScreen> createState() => _CsvPreviewScreenState();
}

class _CsvPreviewScreenState extends State<CsvPreviewScreen> {
  late final String _csvContent;
  late final List<List<String>> _rows;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _csvContent = CsvService().generateCsv(widget.entries);
    _rows = _parseCsv(_csvContent);
  }

  List<List<String>> _parseCsv(String csv) {
    return csv
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => _parseCsvLine(line))
        .toList();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  Future<void> _saveFile() async {
    setState(() => _isSaving = true);

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: 'borrow_tracker_export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(_csvContent.codeUnits),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $result'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headers = _rows.isNotEmpty ? _rows.first : <String>[];
    final dataRows = _rows.length > 1 ? _rows.sublist(1) : <List<String>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Preview'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
            tooltip: 'Save file',
            onPressed: _isSaving ? null : _saveFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.entries.length} entries ready to export',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap the save icon to choose where to save the file.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: headers
                      .map((h) => DataColumn(
                            label: Text(
                              h,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                  rows: dataRows
                      .map((row) => DataRow(
                            cells: row
                                .map((cell) => DataCell(
                                      Text(
                                        cell,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ))
                                .toList(),
                          ))
                      .toList(),
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
