import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'printer_discovery_source.dart';
import 'unified_printer.dart';

class BluetoothPrinterDiscovery implements PrinterDiscoverySource {
  const BluetoothPrinterDiscovery({
    this.timeout = const Duration(seconds: 5),
  });

  final Duration timeout;

  @override
  Future<List<UnifiedPrinter>> discover() async {
    final latest = <String, ScanResult>{};
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        latest[result.device.remoteId.str] = result;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }

    return latest.values.map((result) {
      final remoteId = result.device.remoteId.str;
      final advertisedName = result.advertisementData.advName.trim();
      final platformName = result.device.platformName.trim();
      final name = advertisedName.isNotEmpty
          ? advertisedName
          : platformName.isNotEmpty
              ? platformName
              : remoteId;
      return UnifiedPrinter(
        id: 'bluetooth:$remoteId',
        name: name,
        type: PrinterConnectionType.bluetooth,
        metadata: <String, String>{
          'remoteId': remoteId,
          'rssi': result.rssi.toString(),
        },
      );
    }).toList(growable: false);
  }
}
