
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../services/pdf_render_service.dart';

enum PrinterPaper { thermal58, thermal80, a4 }

class FlutterReportPrinter {
  final PdfRenderService _renderer = PdfRenderService();

  /// Main API: template + data -> PDF bytes
  Future<Uint8List> generatePdf({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
  }) {
    return _renderer.render(templateJson, data);
  }

  /// Generate + Preview
  Future<void> preview({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
  }) async {
    final pdf = await generatePdf(templateJson: templateJson, data: data);
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  /// Generate + Print directly (for thermal)
  Future<void> printDirect({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    String? printerName,
  }) async {
    final pdf = await generatePdf(templateJson: templateJson, data: data);
    await Printing.directPrintPdf(
      printer: printerName != null ? Printer(url: printerName) : const Printer(url: ''),
      onLayout: (_) async => pdf,
    );
  }

  /// Generate + Share (for PDF / A4)
  Future<void> sharePdf({
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    String filename = 'report.pdf',
  }) async {
    final pdf = await generatePdf(templateJson: templateJson, data: data);
    await Printing.sharePdf(bytes: pdf, filename: filename);
  }

  /// List available printers
  Future<List<Printer>> listPrinters() async {
    return await Printing.listPrinters();
  }
}
