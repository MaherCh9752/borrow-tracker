import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/borrow_lend.dart';
import '../services/pdf_service.dart';

/// Screen that previews the generated PDF and allows sharing/printing.
class PdfPreviewScreen extends StatefulWidget {
  final List<BorrowLend> entries;

  const PdfPreviewScreen({super.key, required this.entries});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytes = _generatePdf();
  }

  Future<Uint8List> _generatePdf() async {
    final pdfService = PdfService();
    final doc = await pdfService.generateEntryReport(widget.entries);
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          FutureBuilder<Uint8List>(
            future: _pdfBytes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share PDF',
                onPressed: () => Printing.sharePdf(
                  bytes: snapshot.data!,
                  filename: 'borrow_tracker_export.pdf',
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to generate PDF: ${snapshot.error}'),
                ],
              ),
            );
          }
          return PdfPreview(
            build: (format) => snapshot.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            pdfFileName: 'borrow_tracker_export.pdf',
          );
        },
      ),
    );
  }
}
