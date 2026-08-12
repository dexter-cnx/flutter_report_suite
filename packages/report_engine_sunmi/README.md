# report_engine_sunmi

Optional Android-only Sunmi adapter for `report_engine`.

This companion package keeps `sunmi_printer_plus` out of the cross-platform core package. Use it only in Android applications that target supported Sunmi embedded printers.

## Hardware capabilities

Sunmi models do not all expose the same cutter or cash-drawer hardware. The adapter therefore defaults to **print-only**. Enable optional capability interfaces only after your application has identified a verified hardware profile for the concrete device model.

```dart
final sunmi = SunmiPrinterAdapter(
  hardwareProfile: const SunmiHardwareProfile(
    supportsCutter: true,
    supportsCashDrawer: true,
  ),
);

if (sunmi is CutterCapability) {
  await sunmi.cutPaper();
}
```

Do not set a capability to `true` merely because the plugin exposes the method; validate it against the target Sunmi model/hardware first.

## Discovery and printing

```dart
final sunmi = SunmiPrinterAdapter();

final discovery = PrinterDiscoveryService.standard(
  additionalSources: <PrinterDiscoverySource>[sunmi],
);
final printers = await discovery.discoverAll();

final bytes = await EscPosRenderer().renderQuickReceipt(
  data: data,
  encodingConfig: const EscPosEncodingConfig.raster(),
);
await sunmi.send(bytes);
```

Real-device validation is required before claiming model compatibility.
