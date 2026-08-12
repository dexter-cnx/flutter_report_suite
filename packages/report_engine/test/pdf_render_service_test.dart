import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> documentTemplate({
    required String type,
    required double widthMm,
    double? heightMm,
    List<Map<String, dynamic>>? elements,
  }) {
    return {
      'id': 'pdf-test-$type-$widthMm',
      'paper': {
        'type': type,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'autoHeight': type == 'thermal',
        'marginMm': 3,
      },
      'elements': elements ??
          [
            {
              'id': 'title',
              'type': 'dynamic_text',
              'key': '{{shop.name}}',
              'x': 0,
              'y': 0,
              'w': widthMm - 6,
              'h': 8,
              'style': {'fontSize': 12, 'bold': true},
            },
          ],
    };
  }

  List<Map<String, dynamic>> invoiceColumns() {
    return const [
      {
        'key': 'no',
        'label': 'No.',
        'width': 1,
        'alignment': 'right',
      },
      {
        'key': 'name',
        'label': 'Item',
        'width': 5,
        'alignment': 'left',
      },
      {
        'key': 'qty',
        'label': 'Qty',
        'width': 1,
        'alignment': 'center',
      },
      {
        'key': 'price',
        'label': 'Price',
        'width': 2,
        'alignment': 'right',
      },
    ];
  }

  void expectValidPdf(List<int> bytes) {
    expect(bytes.length, greaterThan(100));
    expect(bytes.take(5), orderedEquals(utf8.encode('%PDF-')));
    final tail = latin1.decode(
      bytes.sublist(bytes.length - 32),
      allowInvalid: true,
    );
    expect(tail, contains('%%EOF'));
  }

  String pdfSource(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

  int pageObjectCount(List<int> bytes) {
    return RegExp(r'/Type\s*/Page\b').allMatches(pdfSource(bytes)).length;
  }

  List<({double width, double height})> mediaBoxes(List<int> bytes) {
    final matches = RegExp(
      r'/MediaBox\s*\[\s*0(?:\.0+)?\s+0(?:\.0+)?\s+([0-9.]+)\s+([0-9.]+)\s*\]',
    ).allMatches(pdfSource(bytes));

    return matches
        .map(
          (match) => (
            width: double.parse(match.group(1)!),
            height: double.parse(match.group(2)!),
          ),
        )
        .toList(growable: false);
  }

  double mmToPoints(double mm) => mm * 72 / 25.4;

  void expectPageWidth(List<int> bytes, double widthMm) {
    final boxes = mediaBoxes(bytes);
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      expect(box.width, closeTo(mmToPoints(widthMm), 0.2));
      expect(box.height, greaterThan(0));
    }
  }

  test('Thermal 80mm regression keeps valid structure and 80mm width', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'thermal', widthMm: 80),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), 1);
    expectPageWidth(bytes, 80);
  });

  test('Thermal 58mm regression keeps valid structure and 58mm width', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'thermal', widthMm: 58),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), 1);
    expectPageWidth(bytes, 58);
  });

  test('renders A4 as a structurally valid PDF with A4 geometry', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'a4', widthMm: 210, heightMm: 297),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThanOrEqualTo(1));
    expectPageWidth(bytes, 210);
    final boxes = mediaBoxes(bytes);
    expect(boxes.first.height, closeTo(mmToPoints(297), 0.2));
  });

  test('A4 invoice regression paginates more than 25 rows', () async {
    final items = List<Map<String, dynamic>>.generate(
      80,
      (index) => {
        'no': index + 1,
        'name': 'Invoice item ${index + 1}',
        'qty': (index % 4) + 1,
        'price': 25 + index,
      },
    );
    final bytes = await PdfRenderService().render(
      documentTemplate(
        type: 'a4',
        widthMm: 210,
        heightMm: 297,
        elements: [
          {
            'id': 'invoice-title',
            'type': 'dynamic_text',
            'key': 'Invoice {{invoiceNo}}',
            'x': 0,
            'y': 0,
            'w': 180,
            'h': 10,
            'style': {'fontSize': 16, 'bold': true},
          },
          {
            'id': 'items',
            'type': 'table',
            'key': '{{items}}',
            'x': 0,
            'y': 12,
            'w': 180,
            'h': 240,
            'style': {'fontSize': 9},
            'columns': invoiceColumns(),
          },
        ],
      ),
      {'invoiceNo': 'INV-REGRESSION-001', 'items': items},
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThan(1));
    expect(mediaBoxes(bytes).length, pageObjectCount(bytes));
    expectPageWidth(bytes, 210);
  });

  test('renders table width weights and per-column alignment metadata', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(
        type: 'a4',
        widthMm: 210,
        heightMm: 297,
        elements: [
          {
            'id': 'layout-table',
            'type': 'table',
            'key': '{{items}}',
            'x': 0,
            'y': 0,
            'w': 180,
            'h': 100,
            'style': {'fontSize': 9},
            'columns': [
              {
                'key': 'name',
                'label': 'Item',
                'width': 3,
                'alignment': 'left',
              },
              {
                'key': 'qty',
                'label': 'Qty',
                'width': 1,
                'alignment': 'center',
              },
              {
                'key': 'price',
                'label': 'Price',
                'width': 2,
                'alignment': 'right',
              },
            ],
          },
        ],
      ),
      const {
        'items': [
          {'name': 'Latte', 'qty': 2, 'price': 130},
          {'name': 'Croissant', 'qty': 1, 'price': 85},
        ],
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThanOrEqualTo(1));
  });

  test('Thai invoice regression renders Thai text and table rows on A4', () async {
    final items = List<Map<String, dynamic>>.generate(
      32,
      (index) => {
        'no': index + 1,
        'name': 'สินค้า ${index + 1} กุ้ง น้ำ',
        'qty': (index % 3) + 1,
        'price': 120 + index,
      },
    );

    final bytes = await PdfRenderService().render(
      documentTemplate(
        type: 'a4',
        widthMm: 210,
        heightMm: 297,
        elements: [
          {
            'id': 'thai-heading',
            'type': 'dynamic_text',
            'key': 'ใบแจ้งหนี้ {{invoiceNo}}',
            'x': 0,
            'y': 0,
            'w': 180,
            'h': 10,
            'style': {'fontSize': 16, 'bold': true},
          },
          {
            'id': 'thai-office',
            'type': 'dynamic_text',
            'key': 'สำนักงาน {{office}} ยอดรวม {{total}} บาท',
            'x': 0,
            'y': 12,
            'w': 180,
            'h': 8,
            'style': {'fontSize': 11},
          },
          {
            'id': 'thai-items',
            'type': 'table',
            'key': '{{items}}',
            'x': 0,
            'y': 22,
            'w': 180,
            'h': 220,
            'style': {'fontSize': 9},
            'columns': [
              {
                'key': 'no',
                'label': 'ลำดับ',
                'width': 1,
                'alignment': 'right',
              },
              {
                'key': 'name',
                'label': 'รายการ',
                'width': 5,
                'alignment': 'left',
              },
              {
                'key': 'qty',
                'label': 'จำนวน',
                'width': 1,
                'alignment': 'center',
              },
              {
                'key': 'price',
                'label': 'ราคา',
                'width': 2,
                'alignment': 'right',
              },
            ],
          },
        ],
      ),
      {
        'invoiceNo': 'INV-TH-2569-001',
        'office': 'เชียงใหม่',
        'total': 4321.50,
        'items': items,
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThanOrEqualTo(1));
    expectPageWidth(bytes, 210);
    expect(bytes.length, greaterThan(5000));
  });

  test('renders Thai and mixed Thai English numeric text with bundled fonts', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(
        type: 'pdf',
        widthMm: 80,
        heightMm: 120,
        elements: [
          {
            'id': 'thai-regular',
            'type': 'dynamic_text',
            'key': '{{thaiRegular}}',
            'x': 0,
            'y': 0,
            'w': 70,
            'h': 8,
            'style': {'fontSize': 11},
          },
          {
            'id': 'thai-bold',
            'type': 'dynamic_text',
            'key': 'สำนักงาน {{office}} / Invoice {{invoiceNo}} / {{total}} บาท',
            'x': 0,
            'y': 10,
            'w': 70,
            'h': 8,
            'style': {'fontSize': 11, 'bold': true},
          },
        ],
      ),
      const {
        'thaiRegular': 'กุ้ง น้ำ สำนักงาน',
        'office': 'เชียงใหม่',
        'invoiceNo': 'INV-2026-001',
        'total': 1234.50,
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThanOrEqualTo(1));
    expectPageWidth(bytes, 80);
    expect(bytes.length, greaterThan(1000));
  });

  test('renders empty data without corrupting the PDF', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'pdf', widthMm: 80, heightMm: 120),
      const {},
    );

    expectValidPdf(bytes);
  });

  test('renders missing optional values without corrupting the PDF', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(
        type: 'pdf',
        widthMm: 80,
        heightMm: 120,
        elements: [
          {
            'id': 'optional',
            'type': 'dynamic_text',
            'key': '{{customer.optionalNote}}',
            'x': 0,
            'y': 0,
            'w': 60,
            'h': 8,
            'style': {'fontSize': 10},
          },
        ],
      ),
      const {
        'customer': {'name': 'Dexter'},
      },
    );

    expectValidPdf(bytes);
  });
}
