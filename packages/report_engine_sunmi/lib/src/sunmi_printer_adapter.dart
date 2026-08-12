import 'package:report_engine/report_engine.dart';

import 'sunmi_printer_bridge.dart';

/// Android-only adapter for the embedded printer on supported Sunmi devices.
///
/// The adapter implements the core ESC/POS transport contract so the same
/// renderer used for Bluetooth printers can send raw bytes to Sunmi hardware.
class SunmiPrinterAdapter implements EscPosTransport, PrinterDiscoverySource {
  SunmiPrinterAdapter({SunmiPrinterBridge? bridge})
      : _bridge = bridge ?? PluginSunmiPrinterBridge();

  final SunmiPrinterBridge _bridge;

  @override
  Future<void> send(List<int> bytes) async {
    await _bridge.printEscPos(bytes);
  }

  @override
  Future<List<UnifiedPrinter>> discover() async {
    final id = (await _bridge.getId())?.trim();
    final type = (await _bridge.getType())?.trim();
    final version = (await _bridge.getVersion())?.trim();
    final stableId = id != null && id.isNotEmpty ? id : 'embedded';
    final displayName =
        type != null && type.isNotEmpty ? 'Sunmi $type' : 'Sunmi Printer';

    return <UnifiedPrinter>[
      UnifiedPrinter(
        id: 'embedded:sunmi:$stableId',
        name: displayName,
        type: PrinterConnectionType.embedded,
        metadata: <String, String>{
          if (id != null && id.isNotEmpty) 'deviceId': id,
          if (type != null && type.isNotEmpty) 'type': type,
          if (version != null && version.isNotEmpty) 'version': version,
          'adapter': 'sunmi_printer_plus',
        },
      ),
    ];
  }

  Future<void> cutPaper() async {
    await _bridge.cutPaper();
  }

  Future<void> openCashDrawer() async {
    await _bridge.openDrawer();
  }

  Future<bool> isCashDrawerOpen() => _bridge.isDrawerOpen();

  /// Rebinds the Android Sunmi printer service after it has been killed or
  /// was not ready during app startup.
  Future<bool> rebindPrinter() => _bridge.rebindPrinter();
}
