# report_engine_sunmi

Optional Android-only Sunmi adapter for `report_engine`.

This package is intentionally separate from the cross-platform core because `sunmi_printer_plus` supports Android only. Keeping the dependency here prevents Sunmi-specific native integration from becoming a requirement for Web/Desktop/iOS consumers of `report_engine`.

## Usage

```dart
final sunmi = SunmiPrinterAdapter();
final renderer = EscPosRenderer();
final bytes = await renderer.renderQuickReceipt(
  data: data,
  encodingConfig: const EscPosEncodingConfig.raster(),
);
await sunmi.send(bytes);
```

Sunmi discovery can participate in the unified discovery service without coupling the core package to the Android plugin:

```dart
final sunmi = SunmiPrinterAdapter();
final discovery = PrinterDiscoveryService.standard(
  additionalSources: <PrinterDiscoverySource>[sunmi],
);
final printers = await discovery.discoverAll();
```

The adapter also exposes `cutPaper()`, `openCashDrawer()`, and `rebindPrinter()`. Formal capability interfaces remain part of Phase 3 Task 12.

Physical device validation is required before claiming compatibility with a specific Sunmi model.
