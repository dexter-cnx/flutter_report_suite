import 'package:report_engine/report_engine.dart';

import 'sunmi_printer_bridge.dart';

/// Capabilities confirmed for the concrete Sunmi model used by the host app.
///
/// The plugin does not expose a reliable universal model-to-capability query,
/// so the safe default is print-only. Host applications should select a profile
/// from their verified device inventory before enabling cutter/drawer actions.
class SunmiHardwareProfile {
  const SunmiHardwareProfile({
    this.supportsCutter = false,
    this.supportsCashDrawer = false,
  });

  final bool supportsCutter;
  final bool supportsCashDrawer;
}

/// Android-only adapter for the embedded printer on supported Sunmi devices.
class SunmiPrinterAdapter implements EscPosTransport, PrinterDiscoverySource {
  factory SunmiPrinterAdapter({
    SunmiPrinterBridge? bridge,
    SunmiHardwareProfile hardwareProfile = const SunmiHardwareProfile(),
  }) {
    final resolvedBridge = bridge ?? PluginSunmiPrinterBridge();
    if (hardwareProfile.supportsCutter &&
        hardwareProfile.supportsCashDrawer) {
      return _SunmiFullCapabilityAdapter(resolvedBridge, hardwareProfile);
    }
    if (hardwareProfile.supportsCutter) {
      return _SunmiCutterAdapter(resolvedBridge, hardwareProfile);
    }
    if (hardwareProfile.supportsCashDrawer) {
      return _SunmiCashDrawerAdapter(resolvedBridge, hardwareProfile);
    }
    return SunmiPrinterAdapter._(resolvedBridge, hardwareProfile);
  }

  SunmiPrinterAdapter._(this._bridge, this.hardwareProfile);

  final SunmiPrinterBridge _bridge;
  final SunmiHardwareProfile hardwareProfile;

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
          'cutter': hardwareProfile.supportsCutter.toString(),
          'cashDrawer': hardwareProfile.supportsCashDrawer.toString(),
        },
      ),
    ];
  }

  /// Rebinds the Android Sunmi printer service after it has been killed or
  /// was not ready during app startup.
  Future<bool> rebindPrinter() => _bridge.rebindPrinter();
}

class _SunmiCutterAdapter extends SunmiPrinterAdapter
    implements CutterCapability {
  _SunmiCutterAdapter(
    super._bridge,
    super.hardwareProfile,
  ) : super._();

  @override
  Future<void> cutPaper() async {
    await _bridge.cutPaper();
  }
}

class _SunmiCashDrawerAdapter extends SunmiPrinterAdapter
    implements CashDrawerCapability {
  _SunmiCashDrawerAdapter(
    super._bridge,
    super.hardwareProfile,
  ) : super._();

  @override
  Future<void> openCashDrawer() async {
    await _bridge.openDrawer();
  }

  @override
  Future<bool> isCashDrawerOpen() => _bridge.isDrawerOpen();
}

class _SunmiFullCapabilityAdapter extends SunmiPrinterAdapter
    implements CutterCapability, CashDrawerCapability {
  _SunmiFullCapabilityAdapter(
    super._bridge,
    super.hardwareProfile,
  ) : super._();

  @override
  Future<void> cutPaper() async {
    await _bridge.cutPaper();
  }

  @override
  Future<void> openCashDrawer() async {
    await _bridge.openDrawer();
  }

  @override
  Future<bool> isCashDrawerOpen() => _bridge.isDrawerOpen();
}
