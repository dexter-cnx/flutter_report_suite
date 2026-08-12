
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report_template.dart';

class PdfRenderService {
  pw.Font? _thaiFont;
  pw.Font? _thaiBold;

  Future<void> _loadFonts() async {
    if (_thaiFont != null) return;
    try {
      final fontData = await rootBundle.load('assets/fonts/THSarabunNew.ttf');
      _thaiFont = pw.Font.ttf(fontData);
      final boldData = await rootBundle.load('assets/fonts/THSarabunNew Bold.ttf');
      _thaiBold = pw.Font.ttf(boldData);
    } catch (_) {
      // fallback to helvetica if fonts not added yet
      _thaiFont = pw.Font.helvetica();
      _thaiBold = pw.Font.helveticaBold();
    }
  }

  dynamic _resolve(String? key, Map<String, dynamic> data) {
    if (key == null) return '';
    String k = key.replaceAll('{{', '').replaceAll('}}', '').trim();
    if (k.isEmpty) return '';
    // support nested like shop.name
    var parts = k.split('.');
    dynamic cur = data;
    for (var p in parts) {
      if (cur is Map && cur.containsKey(p)) cur = cur[p];
      else return key; // return raw if not found
    }
    return cur ?? '';
  }

  Future<Uint8List> render(Map<String, dynamic> templateJson, Map<String, dynamic> data) async {
    await _loadFonts();
    final template = ReportTemplate.fromJson(templateJson);
    final paper = template.paper;

    final doc = pw.Document();

    if (paper.type == 'thermal') {
      // Thermal: single page with infinite height
      final pageFormat = PdfPageFormat(
        paper.widthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: paper.marginMm * PdfPageFormat.mm,
      );
      doc.addPage(pw.Page(
        pageFormat: pageFormat,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: template.elements.map((el) {
              final raw = _resolve(el.key, data);
              final style = el.style;
              final fontSize = (style['fontSize'] ?? 10).toDouble();
              final isBold = style['bold'] == true;
              final align = _toAlign(style['align']);

              if (el.type == 'line') {
                return pw.Container(
                  margin: pw.EdgeInsets.only(top: 2, bottom: 2),
                  height: 0.5, color: PdfColors.black
                );
              }
              if (el.type == 'barcode' || el.type == 'qrcode') {
                return pw.Center(
                  child: pw.BarcodeWidget(
                    data: raw.toString(),
                    barcode: el.type == 'qrcode' ? pw.Barcode.qrCode() : pw.Barcode.code128(),
                    width: el.w, height: el.h,
                  ),
                );
              }
              if (el.type == 'table') {
                List<List<String>> tableData = [];
                if (raw is List) {
                  for (var row in raw) {
                    if (row is Map) {
                      tableData.add(el.columns!.map((c) => (row[c['key']] ?? '').toString()).toList());
                    }
                  }
                }
                return pw.Table.fromTextArray(
                  headers: el.columns?.map((c) => c['label'].toString()).toList(),
                  data: tableData,
                  headerStyle: pw.TextStyle(font: isBold ? _thaiBold : _thaiFont, fontSize: fontSize),
                  cellStyle: pw.TextStyle(font: _thaiFont, fontSize: fontSize - 1),
                  cellAlignment: pw.Alignment.centerLeft,
                );
              }
              return pw.Container(
                width: el.w,
                alignment: align,
                child: pw.Text(raw.toString(), style: pw.TextStyle(font: isBold ? _thaiBold : _thaiFont, fontSize: fontSize)),
              );
            }).toList(),
          );
        },
      ));
    } else {
      // A4 / PDF: MultiPage with header/footer, table page-break support
      doc.addPage(pw.MultiPage(
        pageFormat: paper.type == 'a4' ? PdfPageFormat.a4 : PdfPageFormat(paper.widthMm * PdfPageFormat.mm, (paper.heightMm ?? 297) * PdfPageFormat.mm),
        margin: pw.EdgeInsets.all(paper.marginMm * PdfPageFormat.mm),
        header: (ctx) => template.elements.where((e) => e.style['isHeader'] == true).isEmpty ? pw.SizedBox() :
          pw.Text(_resolve(template.elements.firstWhere((e) => e.style['isHeader'] == true).key, data).toString(), style: pw.TextStyle(font: _thaiFont, fontSize: 14)),
        footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('พิมพ์เมื่อ: ${DateTime.now().toString()}', style: pw.TextStyle(font: _thaiFont, fontSize: 8)),
          pw.Text('หน้า ${ctx.pageNumber}/${ctx.pagesCount}', style: pw.TextStyle(font: _thaiFont, fontSize: 8)),
        ]),
        build: (ctx) {
          List<pw.Widget> widgets = [];
          for (var el in template.elements.where((e) => e.style['isHeader'] != true && e.style['isFooter'] != true)) {
            final raw = _resolve(el.key, data);
            final style = el.style;
            final fontSize = (style['fontSize'] ?? 10).toDouble();
            final isBold = style['bold'] == true;

            if (el.type == 'table' && raw is List) {
              List<List<String>> tableData = raw.map<List<String>>((row) {
                if (row is Map) {
                  return el.columns!.map((c) => (row[c['key']] ?? '').toString()).toList();
                }
                return [row.toString()];
              }).toList();

              widgets.add(pw.Table.fromTextArray(
                headers: el.columns?.map((c) => c['label'].toString()).toList(),
                data: tableData,
                headerStyle: pw.TextStyle(font: _thaiBold, fontSize: fontSize),
                cellStyle: pw.TextStyle(font: _thaiFont, fontSize: fontSize),
              ));
            } else if (el.type != 'line') {
              widgets.add(pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(raw.toString(), style: pw.TextStyle(font: isBold ? _thaiBold : _thaiFont, fontSize: fontSize)),
              ));
            }
          }
          return widgets;
        },
      ));
    }

    return doc.save();
  }

  pw.Alignment _toAlign(String? a) {
    switch (a) {
      case 'center': return pw.Alignment.center;
      case 'right': return pw.Alignment.centerRight;
      default: return pw.Alignment.centerLeft;
    }
  }
}
