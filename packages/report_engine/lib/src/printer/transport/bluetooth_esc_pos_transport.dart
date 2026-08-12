import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'esc_pos_transport.dart';

class BluetoothEscPosTransport implements EscPosTransport {
  BluetoothEscPosTransport(
    this.device, {
    this.connectTimeout = const Duration(seconds: 10),
    this.chunkSize = 180,
    this.chunkDelay = const Duration(milliseconds: 40),
  });

  final BluetoothDevice device;
  final Duration connectTimeout;
  final int chunkSize;
  final Duration chunkDelay;

  @override
  Future<void> send(List<int> bytes) async {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be positive.');
    }

    try {
      await device.connect(timeout: connectTimeout);
      final services = await device.discoverServices();
      final characteristic = _findWritableCharacteristic(services);
      if (characteristic == null) {
        throw StateError('Bluetooth printer has no writable characteristic.');
      }
      await _writeChunks(characteristic, bytes);
    } finally {
      try {
        await device.disconnect();
      } catch (_) {
        // The connection may already be closed by the printer.
      }
    }
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

  Future<void> _writeChunks(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length).toInt();
      await characteristic.write(
        Uint8List.fromList(bytes.sublist(offset, end)),
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );
      if (end < bytes.length && chunkDelay > Duration.zero) {
        await Future<void>.delayed(chunkDelay);
      }
    }
  }
}
