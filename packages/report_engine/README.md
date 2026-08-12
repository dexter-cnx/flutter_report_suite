# report_engine

Offline-first Flutter report engine for rendering shared report-template JSON to PDF, A4, thermal, system-printer, and ESC/POS output with Thai support.

## Features

- Shared `ReportTemplate`, `PaperConfig`, and `ReportElement` contract.
- A4, thermal 80mm, thermal 58mm, and custom-size PDF rendering.
- Multi-page tables with Designer column width/alignment metadata.
- Bundled Noto Sans Thai regular/bold fonts.
- Preview, share, and system-printer output through `printing`.
- ESC/POS rendering with TIS-620, CP874, and rasterized Thai fallback.
- Bluetooth Low Energy transport and unified printer discovery.
- Explicit cutter/cash-drawer capability boundaries.
- Hive-backed local template persistence.

The package is backend-free at runtime and is designed for offline-first applications.

## Supported Flutter targets

The core package is designed for Flutter Web, Android, iOS, Linux, macOS, and Windows. Individual printer transports or host integrations can have narrower platform support.

`flutter_blue_plus` provides Bluetooth Low Energy support only. It does **not** make Bluetooth Classic thermal printers compatible.

Sunmi embedded-printer integration is kept in the separate `report_engine_sunmi` companion package so Android-only dependencies do not leak into cross-platform core.

## Installation

```yaml
dependencies:
  report_engine: ^1.0.0
```

Then import the public API:

```dart
import 'package:report_engine/report_engine.dart';
```

## PDF example

```dart
final template = <String, dynamic>{
  'id': 'receipt',
  'version': 1,
  'paper': <String, dynamic>{
    'type': 'thermal',
    'widthMm': 80,
    'heightMm': 200,
    'autoHeight': true,
    'marginMm': 3,
  },
  'elements': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'shop-name',
      'type': 'dynamic_text',
      'key': '{{shop.name}}',
      'x': 3,
      'y': 3,
      'w': 74,
      'h': 8,
      'style': <String, dynamic>{'bold': true, 'align': 'center'},
    },
  ],
};

final bytes = await PdfRenderService().render(
  template,
  <String, dynamic>{
    'shop': <String, dynamic>{'name': 'ร้านตัวอย่าง'},
  },
);
```

## Preview, share, and system printing

```dart
final printer = FlutterReportPrinter();

await printer.preview(templateJson: template, data: data);
await printer.sharePdf(
  templateJson: template,
  data: data,
  filename: 'receipt.pdf',
);

final printers = await printer.listPrinters();
if (printers.isNotEmpty) {
  await printer.printDirect(
    printer: printers.first,
    templateJson: template,
    data: data,
  );
}
```

## Template storage

```dart
final storage = TemplateStorageService();
await storage.init();
await storage.saveTemplate('receipt', template);
final cached = await storage.getTemplate('receipt');
```

Templates are stored as JSON-compatible values in Hive, so generated Hive adapters are not required.

## Thai ESC/POS

Printer firmware differs in how Thai code pages are assigned. Code-page output therefore requires an explicit printer-specific table number.

```dart
const tis620 = EscPosEncodingConfig.tis620(codeTable: 26);
const cp874 = EscPosEncodingConfig.cp874(codeTable: 30);
const raster = EscPosEncodingConfig.raster();
```

Use TIS-620 or CP874 only when the target printer's code table has been verified. Raster output avoids printer-side Thai character mapping and is the safest fallback when firmware mappings are unknown or unreliable.

Rendering stays separate from transport and hardware operations:

```text
Template + data
      ↓
EscPosRenderer
      ↓
ESC/POS bytes
      ↓
EscPosTransport
      ↓
Physical printer
```

Paper cutting and cash-drawer operations are available only through explicit capabilities. The renderer never inserts an implicit cutter command.

## Printer discovery

`PrinterDiscoveryService` composes independent sources into domain-safe `UnifiedPrinter` values. Core currently includes system-printer discovery and Bluetooth Low Energy discovery, with extension points for additional transports and embedded adapters.

The presence of `usb` or `network` in `PrinterConnectionType` is an extension point and does not imply built-in generic USB/TCP support.

## Physical printer compatibility

Automated tests validate software behavior but do not certify real printer hardware. Printer-specific Thai code tables, Bluetooth mode, cutter support, cash-drawer support, and model quirks must be verified on the actual target device.

The repository maintains the physical evidence matrix in `docs/PRINTER_COMPATIBILITY.md`.

## Validation

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter pub publish --dry-run
```

The reference production toolchain for the repository is Flutter 3.32.7.

## License

MIT. See `LICENSE`.
