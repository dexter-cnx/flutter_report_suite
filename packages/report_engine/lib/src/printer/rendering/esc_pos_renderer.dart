import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../models/report_template.dart';
import '../../services/report_value_resolver.dart';
import '../encoding/esc_pos_encoding_config.dart';
import '../encoding/esc_pos_text_encoder.dart';
import '../encoding/thai_encoding.dart';
import 'esc_pos_rasterizer.dart';

/// Converts report templates and quick-receipt data into ESC/POS bytes.
///
/// Rendering is deliberately transport-agnostic. Bluetooth, USB, network, and
/// embedded printer adapters only receive the resulting byte stream.
class EscPosRenderer {
  EscPosRenderer({
    ReportValueResolver? resolver,
    EscPosTextEncoder? textEncoder,
    EscPosRasterizer? rasterizer,
  })  : _resolver = resolver ?? const ReportValueResolver(),
        _textEncoder = textEncoder ?? const EscPosTextEncoder(),
        _rasterizer = rasterizer ?? FlutterEscPosRasterizer();

  final ReportValueResolver _resolver;
  final EscPosTextEncoder _textEncoder;
  final EscPosRasterizer _rasterizer;

  Future<List<int>> renderTemplate({
    required ReportTemplate template,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];

    for (final element in template.elements) {
      final value = element.type == 'text'
          ? element.key ?? ''
          : _resolver.resolve(element.key, data);
      final text = value.toString();
      final align = _posAlign(element.style['align']?.toString());
      final bold = element.style['bold'] == true;
      final scale = _scale(element.style);

      if (element.type == 'line') {
        bytes.addAll(generator.hr());
        continue;
      }
      if (element.type == 'qrcode') {
        if (text.isNotEmpty) bytes.addAll(generator.qrcode(text));
        continue;
      }
      if (element.type == 'barcode') {
        if (text.isNotEmpty) {
          bytes.addAll(generator.barcode(Barcode.code128(text.codeUnits)));
        }
        continue;
      }
      if (element.type == 'table') {
        if (value is List) {
          for (final row in value) {
            if (row is! Map) continue;
            final cells = element.columns.isEmpty
                ? row.values.map((cell) => cell.toString()).toList()
                : element.columns
                    .map((column) => (row[column['key']] ?? '').toString())
                    .toList();
            await _appendText(
              bytes,
              generator: generator,
              paperSize: paperSize,
              text: cells.join('  '),
              align: align,
              bold: bold,
              scale: scale,
              encodingConfig: encodingConfig,
            );
          }
        }
        continue;
      }
      if (text.isNotEmpty) {
        await _appendText(
          bytes,
          generator: generator,
          paperSize: paperSize,
          text: text,
          align: align,
          bold: bold,
          scale: scale,
          encodingConfig: encodingConfig,
        );
      }
    }

    return bytes;
  }

  Future<List<int>> renderQuickReceipt({
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];
    final shop = data['shop'] is Map ? data['shop'] as Map : const {};

    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: shop['name']?.toString() ?? 'ร้านค้า',
      align: PosAlign.center,
      bold: true,
      scale: 2,
      encodingConfig: encodingConfig,
    );
    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: 'สาขา ${shop['branch'] ?? ''}',
      align: PosAlign.center,
      encodingConfig: encodingConfig,
    );
    bytes.addAll(generator.hr());
    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: 'วันที่ ${data['date'] ?? ''}',
      encodingConfig: encodingConfig,
    );
    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: 'เลขที่ ${data['orderId'] ?? ''}',
      encodingConfig: encodingConfig,
    );
    bytes.addAll(generator.hr());

    final items = data['items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        await _appendText(
          bytes,
          generator: generator,
          paperSize: paperSize,
          text:
              '${item['name'] ?? ''}  x${item['qty'] ?? ''}  ${item['price'] ?? ''}',
          encodingConfig: encodingConfig,
        );
      }
    }

    bytes.addAll(generator.hr());
    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: 'รวม ${data['total'] ?? ''} บาท',
      align: PosAlign.right,
      bold: true,
      scale: 2,
      encodingConfig: encodingConfig,
    );
    final orderId = data['orderId']?.toString() ?? '';
    if (orderId.isNotEmpty) bytes.addAll(generator.qrcode(orderId));
    await _appendText(
      bytes,
      generator: generator,
      paperSize: paperSize,
      text: data['note']?.toString() ?? 'ขอบคุณครับ',
      align: PosAlign.center,
      encodingConfig: encodingConfig,
    );

    return bytes;
  }

  Future<void> _appendText(
    List<int> bytes, {
    required Generator generator,
    required PaperSize paperSize,
    required String text,
    PosAlign align = PosAlign.left,
    bool bold = false,
    int scale = 1,
    EscPosEncodingConfig? encodingConfig,
  }) async {
    if (encodingConfig == null) {
      bytes.addAll(
        generator.text(
          text,
          styles: PosStyles(
            align: align,
            bold: bold,
            height: _textSize(scale),
            width: _textSize(scale),
          ),
        ),
      );
      return;
    }

    if (encodingConfig.thaiEncoding == ThaiEncoding.rasterImage) {
      bytes.addAll(
        await _rasterizer.rasterize(
          text,
          paperSize: paperSize,
          align: align,
          bold: bold,
          scale: scale,
        ),
      );
      return;
    }

    bytes.addAll(_stylePrefix(align: align, bold: bold, scale: scale));
    bytes.addAll(
      _textEncoder.encodeLine(text, config: encodingConfig),
    );
    bytes.addAll(_styleReset());
  }

  List<int> _stylePrefix({
    required PosAlign align,
    required bool bold,
    required int scale,
  }) {
    final multiplier = (scale.clamp(1, 8) - 1).toInt();
    final size = (multiplier << 4) | multiplier;
    return <int>[
      0x1B,
      0x61,
      _alignValue(align),
      0x1B,
      0x45,
      bold ? 1 : 0,
      0x1D,
      0x21,
      size,
    ];
  }

  List<int> _styleReset() => const <int>[
        0x1B,
        0x45,
        0,
        0x1D,
        0x21,
        0,
        0x1B,
        0x61,
        0,
      ];

  int _alignValue(PosAlign align) {
    switch (align) {
      case PosAlign.left:
        return 0;
      case PosAlign.center:
        return 1;
      case PosAlign.right:
        return 2;
    }
  }

  PosAlign _posAlign(String? alignment) {
    switch (alignment) {
      case 'center':
        return PosAlign.center;
      case 'right':
        return PosAlign.right;
      default:
        return PosAlign.left;
    }
  }

  int _scale(Map<String, dynamic> style) {
    final raw = style['scale'] ?? style['textScale'];
    if (raw is num) return raw.toInt().clamp(1, 8);
    return 1;
  }

  PosTextSize _textSize(int scale) {
    switch (scale.clamp(1, 8)) {
      case 2:
        return PosTextSize.size2;
      case 3:
        return PosTextSize.size3;
      case 4:
        return PosTextSize.size4;
      case 5:
        return PosTextSize.size5;
      case 6:
        return PosTextSize.size6;
      case 7:
        return PosTextSize.size7;
      case 8:
        return PosTextSize.size8;
      default:
        return PosTextSize.size1;
    }
  }
}
