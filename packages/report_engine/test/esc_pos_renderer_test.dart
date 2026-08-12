import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EscPosRenderer', () {
    test('renders Thai template text through configured TIS-620 code table',
        () async {
      final renderer = EscPosRenderer();
      final bytes = await renderer.renderTemplate(
        template: _template('ยอดรวม'),
        data: const <String, dynamic>{},
        encodingConfig: const EscPosEncodingConfig.tis620(codeTable: 26),
      );

      expect(
        _containsSequence(
          bytes,
          const <int>[0x1B, 0x74, 26, 0xC2, 0xCD, 0xB4, 0xC3, 0xC7, 0xC1],
        ),
        isTrue,
      );
      expect(_containsSequence(bytes, const <int>[0x1D, 0x56]), isFalse);
    });

    test('uses raster strategy without entering code-page encoder', () async {
      final rasterizer = _FakeRasterizer(const <int>[0x1D, 0x76, 0x30, 0x00, 7]);
      final renderer = EscPosRenderer(rasterizer: rasterizer);

      final bytes = await renderer.renderTemplate(
        template: _template('กุ้ง'),
        data: const <String, dynamic>{},
        encodingConfig: const EscPosEncodingConfig.raster(),
      );

      expect(bytes, containsAllInOrder(<int>[0x1D, 0x76, 0x30, 0x00, 7]));
      expect(rasterizer.calls, 1);
      expect(rasterizer.lastText, 'กุ้ง');
    });

    test('quick receipt routes Thai fields through CP874 strategy', () async {
      final renderer = EscPosRenderer();
      final bytes = await renderer.renderQuickReceipt(
        data: const <String, dynamic>{
          'shop': <String, dynamic>{'name': 'ร้านค้า', 'branch': 'CNX'},
          'date': '2026-08-12',
          'orderId': 'INV-001',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'กุ้ง', 'qty': 1, 'price': 120},
          ],
          'total': 120,
          'note': 'ขอบคุณครับ',
        },
        encodingConfig: const EscPosEncodingConfig.cp874(codeTable: 30),
      );

      expect(_containsSequence(bytes, const <int>[0x1B, 0x74, 30]), isTrue);
      expect(
        _containsSequence(bytes, const <int>[0xA1, 0xD8, 0xE9, 0xA7]),
        isTrue,
      );
      expect(_containsSequence(bytes, const <int>[0x1D, 0x56]), isFalse);
    });
  });
}

ReportTemplate _template(String text) {
  return ReportTemplate(
    id: 'thai-test',
    version: 1,
    paper: const PaperConfig(
      type: 'thermal',
      widthMm: 80,
      autoHeight: true,
    ),
    elements: <ReportElement>[
      ReportElement(
        id: 'title',
        type: 'text',
        key: text,
        x: 0,
        y: 0,
        w: 74,
        h: 10,
      ),
    ],
  );
}

bool _containsSequence(List<int> source, List<int> sequence) {
  if (sequence.isEmpty) return true;
  for (var index = 0; index <= source.length - sequence.length; index++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (source[index + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

class _FakeRasterizer implements EscPosRasterizer {
  _FakeRasterizer(this.bytes);

  final List<int> bytes;
  int calls = 0;
  String? lastText;

  @override
  Future<List<int>> rasterize(
    String text, {
    required PaperSize paperSize,
    PosAlign align = PosAlign.left,
    bool bold = false,
    int scale = 1,
  }) async {
    calls += 1;
    lastText = text;
    return List<int>.from(bytes);
  }
}
