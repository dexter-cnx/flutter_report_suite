import 'esc_pos_encoding_config.dart';
import 'thai_encoding.dart';

/// Pure text-to-byte encoder for ESC/POS code-page printing.
///
/// This class deliberately contains no Bluetooth/USB/network transport logic.
/// It can therefore be tested independently from printer connectivity.
class EscPosTextEncoder {
  const EscPosTextEncoder();

  /// Encodes text as a single-byte payload for the selected Thai strategy.
  ///
  /// TIS-620 and CP874 use the same byte positions for Thai letters, marks,
  /// digits, and the baht sign. CP874-specific punctuation can be added here
  /// without coupling the encoder to a printer transport.
  List<int> encodePayload(
    String text, {
    required EscPosEncodingConfig config,
  }) {
    if (config.thaiEncoding == ThaiEncoding.rasterImage) {
      throw UnsupportedError(
        'Raster Thai encoding must be rendered by the raster text renderer.',
      );
    }

    return text.runes
        .map((rune) => _encodeRune(rune, config.replacementByte))
        .toList(growable: false);
  }

  /// Builds a printer-ready line using the configured `ESC t n` code table.
  ///
  /// The code-table number remains configuration because many ESC/POS clones
  /// assign different values to TIS-620/CP874-compatible tables.
  List<int> encodeLine(
    String text, {
    required EscPosEncodingConfig config,
    bool appendLineFeed = true,
  }) {
    if (config.thaiEncoding == ThaiEncoding.rasterImage) {
      throw UnsupportedError(
        'Raster Thai encoding must be rendered by the raster text renderer.',
      );
    }

    final codeTable = config.codeTable!;
    if (codeTable < 0 || codeTable > 255) {
      throw RangeError.range(codeTable, 0, 255, 'codeTable');
    }

    final bytes = <int>[0x1B, 0x74, codeTable];
    bytes.addAll(encodePayload(text, config: config));
    if (appendLineFeed) bytes.add(0x0A);
    return bytes;
  }

  int _encodeRune(int rune, int replacementByte) {
    if (replacementByte < 0 || replacementByte > 255) {
      throw RangeError.range(replacementByte, 0, 255, 'replacementByte');
    }

    // Printable ASCII plus common control whitespace used in receipt text.
    if (rune <= 0x7F) return rune;

    // TIS-620 / CP874 Thai consonants through sara uue.
    if (rune >= 0x0E01 && rune <= 0x0E3A) {
      return 0xA1 + (rune - 0x0E01);
    }

    // Baht sign.
    if (rune == 0x0E3F) return 0xDF;

    // Thai vowels, tone marks, punctuation, and Thai digits.
    if (rune >= 0x0E40 && rune <= 0x0E5B) {
      return 0xE0 + (rune - 0x0E40);
    }

    return replacementByte;
  }
}
