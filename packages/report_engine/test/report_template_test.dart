import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  test('parses and serializes a report template', () {
    final template = ReportTemplate.fromJson({
      'id': 'receipt',
      'version': 2,
      'paper': {
        'type': 'thermal',
        'widthMm': 80,
        'autoHeight': true,
        'marginMm': 3,
      },
      'elements': [
        {
          'id': 'title',
          'type': 'dynamic_text',
          'key': '{{shop.name}}',
          'x': 0,
          'y': 0,
          'w': 70,
          'h': 8,
          'style': {'fontSize': 12, 'bold': true},
        },
      ],
    });

    expect(template.id, 'receipt');
    expect(template.paper.widthMm, 80);
    expect(template.elements.single.style['bold'], isTrue);
    expect(template.toJson()['version'], 2);
  });

  test('uses safe defaults for optional fields', () {
    final template = ReportTemplate.fromJson(const {});

    expect(template.id, 'template');
    expect(template.version, 1);
    expect(template.paper.type, 'a4');
    expect(template.elements, isEmpty);
  });
}
