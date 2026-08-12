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

  void expectValidPdf(List<int> bytes) {
    expect(bytes.length, greaterThan(100));
    expect(bytes.take(5), orderedEquals(utf8.encode('%PDF-')));
    final tail = latin1.decode(bytes.sublist(bytes.length - 32), allowInvalid: true);
    expect(tail, contains('%%EOF'));
  }

  int pageObjectCount(List<int> bytes) {
    final source = latin1.decode(bytes, allowInvalid: true);
    return RegExp(r'/Type\s*/Page\b').allMatches(source).length;
  }

  test('renders Thermal 80mm as a structurally valid PDF', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'thermal', widthMm: 80),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), 1);
  });

  test('renders Thermal 58mm as a structurally valid PDF', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'thermal', widthMm: 58),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), 1);
  });

  test('renders A4 as a structurally valid PDF', () async {
    final bytes = await PdfRenderService().render(
      documentTemplate(type: 'a4', widthMm: 210, heightMm: 297),
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThanOrEqualTo(1));
  });

  test('paginates a large A4 table', () async {
    final items = List<Map<String, dynamic>>.generate(
      120,
      (index) => {
        'no': index + 1,
        'name': 'Item ${index + 1}',
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
            'id': 'items',
            'type': 'table',
            'key': '{{items}}',
            'x': 0,
            'y': 0,
            'w': 180,
            'h': 240,
            'style': {'fontSize': 9},
            'columns': [
              {'key': 'no', 'label': 'No.'},
              {'key': 'name', 'label': 'Item'},
              {'key': 'qty', 'label': 'Qty'},
              {'key': 'price', 'label': 'Price'},
            ],
          },
        ],
      ),
      {'items': items},
    );

    expectValidPdf(bytes);
    expect(pageObjectCount(bytes), greaterThan(1));
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
