import 'esc_pos_encoding_config.dart';
import 'thai_encoding.dart';

/// Pure text-to-byte encoder for ESC/POS code-page printing.
///
/// This class deliberately contains no Bluetooth/USB/network transport logic.
/// It can therefore be tested independently from printer connectivity.
class EscPosTextEncoder {
  const EscPosTextEncoder();

  /// Encodes text as a single-byte payload for the selected Thai strategy.
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
        .map((rune) => _encodeRune(rune, config))
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

  int _encodeRune(int rune, EscPosEncodingConfig config) {
    final replacementByte = config.replacementByte;
    if (replacementByte < 0 || replacementByte > 255) {
      throw RangeError.range(replacementByte, 0, 255, 'replacementByte');
    }

    if (rune <= 0x7F) return rune;

    // TIS-620 / CP874 Thai consonants through sara uue.
    if (rune >= 0x0E01 && rune <= 0x0E3A) {
      return 0xA1 + (rune - 0x0E01);
    }

    if (rune == 0x0E3F) return 0xDF;

    // Thai vowels, tone marks, punctuation, and Thai digits.
    if (rune >= 0x0E40 && rune <= 0x0E5B) {
      return 0xE0 + (rune - 0x0E40);
    }

    if (config.thaiEncoding == ThaiEncoding.cp874) {
      final cp874 = _cp874Extension(rune);
      if (cp874 != null) return cp874;
    }

    return replacementByte;
  }

  int? _cp874Extension(int rune) {
    switch (rune) {
      case 0x20AC: // €
        return 0x80;
      case 0x2026: // …
        return 0x85;
      case 0x2018: // ‘
        return 0x91;
      case 0x2019: // ’
        return 0x92;
      case 0x201C: // “
        return 0x93;
      case 0x201D: // ”
        return 0x94;
      case 0x2022: // •
        return 0x95;
      case 0x2013: // –
        return 0x96;
      case 0x2014: // —
        return 0x97;
      default:
        return null;
    }
  }
}
