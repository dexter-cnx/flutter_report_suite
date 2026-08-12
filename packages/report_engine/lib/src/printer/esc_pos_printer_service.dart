import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/report_value_resolver.dart';
import 'encoding/esc_pos_encoding_config.dart';
import 'rendering/esc_pos_renderer.dart';
import 'transport/bluetooth_esc_pos_transport.dart';
import 'transport/esc_pos_transport.dart';

class EscPosPrinterService {
  EscPosPrinterService({
    ReportValueResolver? resolver,
    EscPosRenderer? renderer,
  }) : _renderer = renderer ?? EscPosRenderer(resolver: resolver);

  final EscPosRenderer _renderer;

  Future<List<ScanResult>> scanPrinters({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = <ScanResult>[];
    final subscription = FlutterBluePlus.scanResults.listen((value) {
      results
        ..clear()
        ..addAll(value);
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }
    return List.unmodifiable(results);
  }

  /// Backwards-compatible Bluetooth receipt printing entry point.
  ///
  /// [encodingConfig] opts into explicit Thai code-page or raster rendering.
  /// When omitted, legacy `esc_pos_utils_plus` text encoding is preserved.
  Future<void> printReceipt({
    required BluetoothDevice device,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
    bool cutAfterPrint = true,
  }) {
    return printReceiptWithTransport(
      transport: BluetoothEscPosTransport(device),
      templateJson: templateJson,
      data: data,
      paperSize: paperSize,
      encodingConfig: encodingConfig,
      cutAfterPrint: cutAfterPrint,
    );
  }

  /// Renders independently from the connection mechanism and sends the bytes
  /// through the supplied transport adapter.
  Future<void> printReceiptWithTransport({
    required EscPosTransport transport,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
    bool cutAfterPrint = true,
  }) async {
    final template = ReportTemplate.fromJson(templateJson);
    final bytes = await _renderer.renderTemplate(
      template: template,
      data: data,
      paperSize: paperSize,
      encodingConfig: encodingConfig,
    );
    if (cutAfterPrint) {
      bytes.addAll(await _legacyCutBytes(paperSize));
    }
    await transport.send(bytes);
  }

  Future<List<int>> buildQuickReceipt({
    required Map<String, dynamic> data,
    PaperSize paper = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
    bool includeCut = true,
  }) async {
    final bytes = await _renderer.renderQuickReceipt(
      data: data,
      paperSize: paper,
      encodingConfig: encodingConfig,
    );
    if (includeCut) {
      bytes.addAll(await _legacyCutBytes(paper));
    }
    return bytes;
  }

  /// Temporary compatibility bridge until Task 12 moves cutting behind an
  /// explicit printer capability. Renderers themselves never emit cut commands.
  Future<List<int>> _legacyCutBytes(PaperSize paperSize) async {
    final profile = await CapabilityProfile.load();
    return Generator(paperSize, profile).cut();
  }
}
