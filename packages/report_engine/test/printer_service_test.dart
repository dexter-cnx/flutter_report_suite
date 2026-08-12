import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

class _FakeRenderer extends PdfRenderService {
  @override
  Future<Uint8List> render(
    Map<String, dynamic> templateJson,
    Map<String, dynamic> data,
  ) async {
    return Uint8List.fromList([1, 2, 3, 4]);
  }
}

void main() {
  test('generatePdf delegates to the injected renderer', () async {
    final printer = FlutterReportPrinter(renderer: _FakeRenderer());

    final bytes = await printer.generatePdf(
      templateJson: const {'id': 'test'},
      data: const {'value': 42},
    );

    expect(bytes, orderedEquals([1, 2, 3, 4]));
  });
}
