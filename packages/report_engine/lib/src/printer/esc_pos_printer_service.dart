import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/report_template.dart';
import '../services/report_value_resolver.dart';
import 'capabilities/printer_hardware_capabilities.dart';
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
  /// Bluetooth transport does not imply cutter support. Set [cutAfterPrint] to
  /// false unless a transport-specific cutter capability is supplied through
  /// [printReceiptWithTransport].
  Future<void> printReceipt({
    required BluetoothDevice device,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
    bool cutAfterPrint = false,
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
  ///
  /// Hardware operations are delegated only to explicit capabilities. A
  /// request to cut without a [CutterCapability] fails before bytes are sent.
  Future<void> printReceiptWithTransport({
    required EscPosTransport transport,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
    bool cutAfterPrint = false,
    CutterCapability? cutter,
  }) async {
    if (cutAfterPrint && cutter == null) {
      throw UnsupportedError(
        'This printer transport does not expose a cutter capability.',
      );
    }

    final template = ReportTemplate.fromJson(templateJson);
    final bytes = await _renderer.renderTemplate(
      template: template,
      data: data,
      paperSize: paperSize,
      encodingConfig: encodingConfig,
    );
    await transport.send(bytes);

    if (cutAfterPrint) {
      await cutter!.cutPaper();
    }
  }

  Future<List<int>> buildQuickReceipt({
    required Map<String, dynamic> data,
    PaperSize paper = PaperSize.mm80,
    EscPosEncodingConfig? encodingConfig,
  }) {
    return _renderer.renderQuickReceipt(
      data: data,
      paperSize: paper,
      encodingConfig: encodingConfig,
    );
  }
}
