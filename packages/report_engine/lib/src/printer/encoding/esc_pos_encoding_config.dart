import 'thai_encoding.dart';

/// Printer-specific ESC/POS text encoding configuration.
///
/// ESC/POS code-table numbers are not standardized across all printer models,
/// so callers must provide the table number documented by the target printer.
class EscPosEncodingConfig {
  const EscPosEncodingConfig._({
    required this.thaiEncoding,
    required this.codeTable,
    required this.replacementByte,
  });

  const EscPosEncodingConfig.tis620({
    required int codeTable,
    int replacementByte = 0x3F,
  }) : this._(
          thaiEncoding: ThaiEncoding.tis620,
          codeTable: codeTable,
          replacementByte: replacementByte,
        );

  const EscPosEncodingConfig.cp874({
    required int codeTable,
    int replacementByte = 0x3F,
  }) : this._(
          thaiEncoding: ThaiEncoding.cp874,
          codeTable: codeTable,
          replacementByte: replacementByte,
        );

  const EscPosEncodingConfig.raster()
      : this._(
          thaiEncoding: ThaiEncoding.rasterImage,
          codeTable: null,
          replacementByte: 0x3F,
        );

  final ThaiEncoding thaiEncoding;

  /// Value used with ESC/POS `ESC t n` for this specific printer profile.
  ///
  /// This is non-null for every code-page configuration because callers can
  /// only construct TIS-620/CP874 configs through the named constructors.
  final int? codeTable;

  /// Byte emitted for characters that cannot be represented by the selected
  /// single-byte code page.
  final int replacementByte;
}
