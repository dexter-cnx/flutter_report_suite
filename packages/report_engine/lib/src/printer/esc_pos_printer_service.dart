import 'dart:async';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/report_template.dart';
import '../services/report_value_resolver.dart';

class EscPosPrinterService {
  EscPosPrinterService({ReportValueResolver? resolver})
      : _resolver = resolver ?? const ReportValueResolver();

  final ReportValueResolver _resolver;

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

  Future<void> printReceipt({
    required BluetoothDevice device,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      final characteristic = _findWritableCharacteristic(services);
      if (characteristic == null) {
        throw StateError('Bluetooth printer has no writable characteristic.');
      }

      final bytes = await _buildTemplateBytes(
        template: ReportTemplate.fromJson(templateJson),
        data: data,
        paperSize: paperSize,
      );
      await _writeChunks(characteristic, bytes);
    } finally {
      try {
        await device.disconnect();
      } catch (_) {
        // The connection may already be closed by the printer.
      }
    }
  }

  Future<List<int>> buildQuickReceipt({
    required Map<String, dynamic> data,
    PaperSize paper = PaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    final bytes = <int>[];
    final shop = data['shop'] is Map ? data['shop'] as Map : const {};

    bytes.addAll(generator.text(
      shop['name']?.toString() ?? 'ร้านค้า',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.text(
      'สาขา ${shop['branch'] ?? ''}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('วันที่ ${data['date'] ?? ''}'));
    bytes.addAll(generator.text('เลขที่ ${data['orderId'] ?? ''}'));
    bytes.addAll(generator.hr());

    final items = data['items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        bytes.addAll(generator.row([
          PosColumn(text: item['name']?.toString() ?? '', width: 8),
          PosColumn(
            text: 'x${item['qty'] ?? ''}',
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item['price']?.toString() ?? '',
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]));
      }
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'รวม ${data['total'] ?? ''} บาท',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.right,
        height: PosTextSize.size2,
      ),
    ));
    final orderId = data['orderId']?.toString() ?? '';
    if (orderId.isNotEmpty) bytes.addAll(generator.qrcode(orderId));
    bytes.addAll(generator.text(
      data['note']?.toString() ?? 'ขอบคุณครับ',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.cut());
    return bytes;
  }

  BluetoothCharacteristic? _findWritableCharacteristic(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          return characteristic;
        }
      }
    }
    return null;
  }

  Future<List<int>> _buildTemplateBytes({
    required ReportTemplate template,
    required Map<String, dynamic> data,
    required PaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];

    for (final element in template.elements) {
      final value = element.type == 'text'
          ? element.key ?? ''
          : _resolver.resolve(element.key, data);
      final text = value.toString();
      final styles = PosStyles(
        align: _posAlign(element.style['align']?.toString()),
        bold: element.style['bold'] == true,
      );

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
          bytes.addAll(generator.barcode(Barcode.code128(text)));
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
            bytes.addAll(generator.text(cells.join('  '), styles: styles));
          }
        }
        continue;
      }
      if (text.isNotEmpty) {
        bytes.addAll(generator.text(text, styles: styles));
      }
    }

    bytes.addAll(generator.cut());
    return bytes;
  }

  Future<void> _writeChunks(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    const chunkSize = 180;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length).toInt();
      await characteristic.write(
        Uint8List.fromList(bytes.sublist(offset, end)),
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
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
}
