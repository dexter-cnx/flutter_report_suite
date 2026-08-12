import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a basic PDF document', () async {
    final bytes = await PdfRenderService().render(
      {
        'id': 'pdf-test',
        'paper': {
          'type': 'pdf',
          'widthMm': 80,
          'heightMm': 120,
          'autoHeight': false,
          'marginMm': 3,
        },
        'elements': [
          {
            'id': 'title',
            'type': 'dynamic_text',
            'key': '{{shop.name}}',
            'x': 0,
            'y': 0,
            'w': 60,
            'h': 8,
            'style': {'fontSize': 12, 'bold': true},
          },
          {
            'id': 'literal',
            'type': 'text',
            'key': 'Thank you',
            'x': 0,
            'y': 10,
            'w': 60,
            'h': 8,
            'style': {'fontSize': 10},
          },
        ],
      },
      {
        'shop': {'name': 'Dexter Coffee'},
      },
    );

    expect(bytes.length, greaterThan(100));
    expect(bytes.take(4), orderedEquals([0x25, 0x50, 0x44, 0x46]));
  });
}
