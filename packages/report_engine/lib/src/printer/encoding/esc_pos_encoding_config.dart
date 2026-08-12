import 'thai_encoding.dart';

/// Printer-specific ESC/POS text encoding configuration.
///
/// ESC/POS code-table numbers are not standardized across all printer models,
/// so callers must provide the table number documented by the target printer.
class EscPosEncodingConfig {
  const EscPosEncodingConfig({
    required this.thaiEncoding,
    this.codeTable,
    this.replacementByte = 0x3F,
  }) : assert(
          thaiEncoding == ThaiEncoding.rasterImage || codeTable != null,
          'Code-page Thai encodings require a printer code-table number.',
        );

  const EscPosEncodingConfig.tis620({
    required int codeTable,
    int replacementByte = 0x3F,
  }) : this(
          thaiEncoding: ThaiEncoding.tis620,
          codeTable: codeTable,
          replacementByte: replacementByte,
        );

  const EscPosEncodingConfig.cp874({
    required int codeTable,
    int replacementByte = 0x3F,
  }) : this(
          thaiEncoding: ThaiEncoding.cp874,
          codeTable: codeTable,
          replacementByte: replacementByte,
        );

  const EscPosEncodingConfig.raster()
      : thaiEncoding = ThaiEncoding.rasterImage,
        codeTable = null,
        replacementByte = 0x3F;

  final ThaiEncoding thaiEncoding;

  /// Value used with ESC/POS `ESC t n` for this specific printer profile.
  final int? codeTable;

  /// Byte emitted for characters that cannot be represented by the selected
  /// single-byte code page.
  final int replacementByte;
}
