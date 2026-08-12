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

    test('quick receipt preserves 8/2/2 code-page item columns', () async {
      const config = EscPosEncodingConfig.cp874(codeTable: 30);
      const encoder = EscPosTextEncoder();
      final renderer = EscPosRenderer();
      final bytes = await renderer.renderQuickReceipt(
        data: const <String, dynamic>{
          'shop': <String, dynamic>{'name': 'Shop'},
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Long item name that must stay in name',
              'qty': 2,
              'price': 120,
            },
          ],
          'total': 120,
        },
        encodingConfig: config,
      );

      const expectedLine =
          'Long item name that must stay in   x2        120';
      expect(
        _containsSequence(
          bytes,
          encoder.encodeLine(expectedLine, config: config),
        ),
        isTrue,
      );
    });

    test('quick receipt uses measured raster columns', () async {
      final rasterizer = _FakeRasterizer(const <int>[0x1D, 0x76, 0x30, 0x00, 7]);
      final renderer = EscPosRenderer(rasterizer: rasterizer);

      await renderer.renderQuickReceipt(
        data: const <String, dynamic>{
          'shop': <String, dynamic>{'name': 'ร้านค้า'},
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'กุ้ง', 'qty': 1, 'price': 120},
          ],
          'total': 120,
        },
        encodingConfig: const EscPosEncodingConfig.raster(),
      );

      expect(rasterizer.columnCalls, 1);
      expect(rasterizer.lastColumns!.map((column) => column.flex), <int>[8, 2, 2]);
      expect(rasterizer.lastColumns![1].align, PosAlign.center);
      expect(rasterizer.lastColumns![2].align, PosAlign.right);
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
  int columnCalls = 0;
  String? lastText;
  List<EscPosRasterColumn>? lastColumns;

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

  @override
  Future<List<int>> rasterizeColumns(
    List<EscPosRasterColumn> columns, {
    required PaperSize paperSize,
    int scale = 1,
  }) async {
    columnCalls += 1;
    lastColumns = List<EscPosRasterColumn>.from(columns);
    return List<int>.from(bytes);
  }
}
