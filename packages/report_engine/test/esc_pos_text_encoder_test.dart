import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  const encoder = EscPosTextEncoder();

  group('EscPosTextEncoder', () {
    test('encodes required Thai fixtures as TIS-620 bytes', () {
      const config = EscPosEncodingConfig.tis620(codeTable: 26);

      expect(
        encoder.encodePayload('กุ้ง', config: config),
        <int>[0xA1, 0xD8, 0xE9, 0xA7],
      );
      expect(
        encoder.encodePayload('น้ำ', config: config),
        <int>[0xB9, 0xE9, 0xD3],
      );
      expect(
        encoder.encodePayload('ยอดรวม', config: config),
        <int>[0xC2, 0xCD, 0xB4, 0xC3, 0xC7, 0xC1],
      );
    });

    test('encodes mixed Thai English and numeric content', () {
      const config = EscPosEncodingConfig.cp874(codeTable: 30);

      expect(
        encoder.encodePayload('Total ยอดรวม 123', config: config),
        <int>[
          0x54,
          0x6F,
          0x74,
          0x61,
          0x6C,
          0x20,
          0xC2,
          0xCD,
          0xB4,
          0xC3,
          0xC7,
          0xC1,
          0x20,
          0x31,
          0x32,
          0x33,
        ],
      );
    });

    test('encodes Thai numerals', () {
      const config = EscPosEncodingConfig.cp874(codeTable: 30);

      expect(
        encoder.encodePayload('๐๑๒๓๔๕๖๗๘๙', config: config),
        <int>[0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9],
      );
    });

    test('prefixes configured ESC/POS code table command', () {
      const config = EscPosEncodingConfig.tis620(codeTable: 26);

      expect(
        encoder.encodeLine('ก', config: config),
        <int>[0x1B, 0x74, 26, 0xA1, 0x0A],
      );
    });

    test('supports CP874 punctuation extension bytes', () {
      const config = EscPosEncodingConfig.cp874(codeTable: 30);

      expect(
        encoder.encodePayload('€…“ไทย”', config: config),
        <int>[0x80, 0x85, 0x93, 0xE4, 0xB7, 0xC2, 0x94],
      );
    });

    test('TIS-620 replaces characters outside its repertoire', () {
      const config = EscPosEncodingConfig.tis620(
        codeTable: 26,
        replacementByte: 0x3F,
      );

      expect(
        encoder.encodePayload('A€B', config: config),
        <int>[0x41, 0x3F, 0x42],
      );
    });

    test('keeps raster strategy isolated from code-page encoding', () {
      expect(
        () => encoder.encodePayload(
          'กุ้ง',
          config: const EscPosEncodingConfig.raster(),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
