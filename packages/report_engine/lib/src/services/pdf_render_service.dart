import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_template.dart';
import 'report_value_resolver.dart';

class PdfRenderService {
  PdfRenderService({ReportValueResolver? resolver})
      : _resolver = resolver ?? const ReportValueResolver();

  final ReportValueResolver _resolver;
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<Uint8List> render(
    Map<String, dynamic> templateJson,
    Map<String, dynamic> data,
  ) async {
    await _loadFonts();
    final template = ReportTemplate.fromJson(templateJson);
    final document = pw.Document();

    if (template.paper.type == 'thermal') {
      _addThermalPage(document, template, data);
    } else {
      _addPagedDocument(document, template, data);
    }

    return document.save();
  }

  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    try {
      final regular = await rootBundle.load('assets/fonts/THSarabunNew.ttf');
      final bold = await rootBundle.load('assets/fonts/THSarabunNew Bold.ttf');
      _regularFont = pw.Font.ttf(regular);
      _boldFont = pw.Font.ttf(bold);
    } catch (_) {
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  void _addThermalPage(
    pw.Document document,
    ReportTemplate template,
    Map<String, dynamic> data,
  ) {
    final paper = template.paper;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          paper.widthMm * PdfPageFormat.mm,
          double.infinity,
          marginAll: paper.marginMm * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: template.elements
              .map((element) => _buildElement(element, data))
              .toList(growable: false),
        ),
      ),
    );
  }

  void _addPagedDocument(
    pw.Document document,
    ReportTemplate template,
    Map<String, dynamic> data,
  ) {
    final paper = template.paper;
    final pageFormat = paper.type == 'a4'
        ? PdfPageFormat.a4
        : PdfPageFormat(
            paper.widthMm * PdfPageFormat.mm,
            (paper.heightMm ?? 297) * PdfPageFormat.mm,
          );
    final headers = template.elements
        .where((element) => element.style['isHeader'] == true)
        .toList(growable: false);
    final body = template.elements
        .where((element) =>
            element.style['isHeader'] != true &&
            element.style['isFooter'] != true)
        .toList(growable: false);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(paper.marginMm * PdfPageFormat.mm),
        header: headers.isEmpty
            ? null
            : (_) => pw.Column(
                  children: headers
                      .map((element) => _buildElement(element, data))
                      .toList(growable: false),
                ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Printed: ${DateTime.now().toIso8601String()}',
              style: _textStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: _textStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => body
            .map((element) => _buildElement(element, data))
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _buildElement(
    ReportElement element,
    Map<String, dynamic> data,
  ) {
    final style = element.style;
    final fontSize = _double(style['fontSize'], 10);
    final isBold = style['bold'] == true;
    final value = _valueFor(element, data);

    switch (element.type) {
      case 'line':
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 2),
          height: _double(style['thickness'], 0.5),
          color: PdfColors.black,
        );
      case 'qrcode':
      case 'barcode':
        final text = value.toString();
        if (text.isEmpty) return pw.SizedBox();
        return pw.Align(
          alignment: _alignment(style['align']?.toString()),
          child: pw.BarcodeWidget(
            data: text,
            barcode: element.type == 'qrcode'
                ? pw.Barcode.qrCode()
                : pw.Barcode.code128(),
            width: element.w * PdfPageFormat.mm,
            height: element.h * PdfPageFormat.mm,
          ),
        );
      case 'table':
        return _buildTable(element, value, fontSize);
      default:
        return pw.Container(
          width: element.w > 0 ? element.w * PdfPageFormat.mm : null,
          alignment: _alignment(style['align']?.toString()),
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            value.toString(),
            textAlign: _textAlign(style['align']?.toString()),
            style: _textStyle(fontSize: fontSize, bold: isBold),
          ),
        );
    }
  }

  pw.Widget _buildTable(
    ReportElement element,
    dynamic value,
    double fontSize,
  ) {
    if (value is! List || element.columns.isEmpty) return pw.SizedBox();

    final rows = value.map<List<String>>((row) {
      if (row is! Map) return [row.toString()];
      return element.columns
          .map((column) => (row[column['key']] ?? '').toString())
          .toList(growable: false);
    }).toList(growable: false);

    return pw.TableHelper.fromTextArray(
      headers: element.columns
          .map((column) => column['label']?.toString() ?? '')
          .toList(growable: false),
      data: rows,
      headerStyle: _textStyle(fontSize: fontSize, bold: true),
      cellStyle: _textStyle(fontSize: fontSize),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  dynamic _valueFor(ReportElement element, Map<String, dynamic> data) {
    if (element.type == 'text') return element.key ?? '';
    return _resolver.resolve(element.key, data);
  }

  pw.TextStyle _textStyle({required double fontSize, bool bold = false}) {
    return pw.TextStyle(
      font: bold ? _boldFont : _regularFont,
      fontSize: fontSize,
    );
  }

  pw.Alignment _alignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  pw.TextAlign _textAlign(String? alignment) {
    switch (alignment) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  double _double(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
