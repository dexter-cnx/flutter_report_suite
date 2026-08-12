import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rasterizes text into printer-ready ESC/POS image commands.
abstract interface class EscPosRasterizer {
  Future<List<int>> rasterize(
    String text, {
    required PaperSize paperSize,
    PosAlign align = PosAlign.left,
    bool bold = false,
    int scale = 1,
  });
}

/// Flutter-backed rasterizer used when a printer's Thai code pages are missing
/// or unreliable.
///
/// Text is rendered with the report engine's bundled Noto Sans Thai fonts and
/// converted to the ESC/POS `GS v 0` monochrome raster command.
class FlutterEscPosRasterizer implements EscPosRasterizer {
  FlutterEscPosRasterizer({
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.threshold = 160,
  });

  static const _fontFamily = 'ReportEngineNotoSansThai';
  static Future<void>? _fontLoadFuture;

  final int horizontalPadding;
  final int verticalPadding;
  final int threshold;

  @override
  Future<List<int>> rasterize(
    String text, {
    required PaperSize paperSize,
    PosAlign align = PosAlign.left,
    bool bold = false,
    int scale = 1,
  }) async {
    if (text.isEmpty) return const <int>[];
    if (scale < 1 || scale > 8) {
      throw RangeError.range(scale, 1, 8, 'scale');
    }
    if (threshold < 0 || threshold > 255) {
      throw RangeError.range(threshold, 0, 255, 'threshold');
    }

    await _ensureFontsLoaded();

    final width = paperSize.width;
    final contentWidth = (width - (horizontalPadding * 2)).toDouble();
    if (contentWidth <= 0) {
      throw StateError('Raster horizontal padding exceeds paper width.');
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontFamily: _fontFamily,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 24.0 * scale,
          height: 1.2,
        ),
      ),
      textAlign: _textAlign(align),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);

    final height = painter.height.ceil() + (verticalPadding * 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.white,
    );
    painter.paint(
      canvas,
      Offset(horizontalPadding.toDouble(), verticalPadding.toDouble()),
    );
    painter.dispose();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) {
      throw StateError('Unable to read rasterized text pixels.');
    }

    return _toGsV0(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      width: width,
      height: height,
    );
  }

  Future<void> _ensureFontsLoaded() {
    return _fontLoadFuture ??= _loadFonts();
  }

  Future<void> _loadFonts() async {
    final regular = await rootBundle.load(
      'packages/report_engine/assets/fonts/NotoSansThai-Regular.ttf',
    );
    final bold = await rootBundle.load(
      'packages/report_engine/assets/fonts/NotoSansThai-Bold.ttf',
    );
    final loader = FontLoader(_fontFamily)
      ..addFont(Future<ByteData>.value(regular))
      ..addFont(Future<ByteData>.value(bold));
    await loader.load();
  }

  List<int> _toGsV0(
    Uint8List rgba, {
    required int width,
    required int height,
  }) {
    final widthBytes = (width + 7) ~/ 8;
    final output = <int>[
      0x1D,
      0x76,
      0x30,
      0x00,
      widthBytes & 0xFF,
      (widthBytes >> 8) & 0xFF,
      height & 0xFF,
      (height >> 8) & 0xFF,
    ];

    for (var y = 0; y < height; y++) {
      for (var byteX = 0; byteX < widthBytes; byteX++) {
        var packed = 0;
        for (var bit = 0; bit < 8; bit++) {
          final x = (byteX * 8) + bit;
          if (x >= width) continue;
          final pixel = ((y * width) + x) * 4;
          final alpha = rgba[pixel + 3];
          if (alpha == 0) continue;
          final luminance =
              (rgba[pixel] + rgba[pixel + 1] + rgba[pixel + 2]) ~/ 3;
          if (luminance < threshold) {
            packed |= 0x80 >> bit;
          }
        }
        output.add(packed);
      }
    }
    return output;
  }

  TextAlign _textAlign(PosAlign align) {
    switch (align) {
      case PosAlign.center:
        return TextAlign.center;
      case PosAlign.right:
        return TextAlign.right;
      case PosAlign.left:
        return TextAlign.left;
    }
  }
}
