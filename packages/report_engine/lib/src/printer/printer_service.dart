import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../services/pdf_render_service.dart';

class FlutterReportPrinter {
  FlutterReportPrinter({PdfRenderService? renderer})
      : _renderer = renderer ?? PdfRenderService();

  final PdfRenderService _renderer;

  Future<Uint8List> generatePdf({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
  }) {
    return _renderer.render(templateJson, data);
  }

  Future<bool> preview({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
  }) async {
    final bytes = await generatePdf(templateJson: templateJson, data: data);
    return Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<bool> printDirect({
    required Printer printer,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
  }) async {
    final bytes = await generatePdf(templateJson: templateJson, data: data);
    return Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => bytes,
    );
  }

  Future<void> sharePdf({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    String filename = 'report.pdf',
  }) async {
    final bytes = await generatePdf(templateJson: templateJson, data: data);
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<List<Printer>> listPrinters() => Printing.listPrinters();
}
