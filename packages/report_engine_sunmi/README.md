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

The adapter also exposes `cutPaper()` and `openCashDrawer()` when supported by the attached Sunmi hardware. Formal capability interfaces remain part of Phase 3 Task 12.

Physical device validation is required before claiming compatibility with a specific Sunmi model.
