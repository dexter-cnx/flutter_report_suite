# Code Walkthrough

This walkthrough describes the production architecture of `flutter_report_suite` after Phase 4 hardening. It focuses on the boundaries that should remain stable as the project moves toward v1.0.0.

## 1. Repository map

```text
flutter_report_suite/
├── .github/workflows/ci.yml
├── apps/
│   └── designer/
├── packages/
│   ├── report_engine/
│   │   ├── assets/fonts/
│   │   ├── assets/templates/
│   │   ├── example/
│   │   ├── lib/
│   │   └── test/
│   └── report_engine_sunmi/
│       ├── lib/
│       └── test/
└── docs/
    ├── PROJECT_HANDOFF.md
    ├── CODE_WALKTHROUGH.md
    ├── PRINTER_COMPATIBILITY.md
    ├── PHASE3_SUNMI_ADAPTER_AUDIT.md
    └── PHASE3_TASK9_11_VALIDATION.md
```

Dependency direction:

```text
apps/designer
      ↓
report_engine
      ↑
report_engine_sunmi
```

`report_engine` stays cross-platform. `report_engine_sunmi` is an optional Android-specific integration package so Sunmi dependencies do not contaminate Web, desktop, or iOS consumers.

---

# TEMPLATE AND DESIGNER

## 2. Shared template contract

The shared model lives under:

```text
packages/report_engine/lib/src/models/
```

Important types include:

```text
ReportTemplate
PaperConfig
ReportElement
```

Geometry is stored in physical millimeters:

```text
stored geometry       = millimeters
Designer presentation = millimeters × zoom
PDF geometry          = millimeters → PDF points
```

This is why Designer zoom does not change persisted document geometry.

A template can contain static text, dynamic text, lines, tables, QR codes, and barcodes. The same JSON contract is consumed by PDF and ESC/POS paths.

## 3. Value resolution

File:

```text
packages/report_engine/lib/src/services/report_value_resolver.dart
```

The resolver supports:

- nested map paths
- list indexes
- interpolation
- null/missing values
- invalid indexes
- numeric and boolean values

Typical expressions:

```dart
resolver.resolve('{{shop.name}}', data);
resolver.resolve('{{items.0.name}}', data);
resolver.resolveText('Invoice {{invoiceNo}}', data);
```

Keeping resolution in one service prevents PDF and ESC/POS semantics from drifting apart.

## 4. Designer responsibilities

`apps/designer` authors the shared template model and provides:

- built-in template gallery
- save/load with Hive
- Save As, rename, duplicate, delete
- JSON import/export/share
- table-column editor
- 5mm snap-to-grid
- center guides and rulers
- 50%–200% zoom
- undo/redo
- keyboard shortcuts and nudging

The Designer is a template-authoring application. Rendering and hardware-specific behavior remain in the engine packages.

---

# PDF STACK

## 5. `PdfRenderService`

File:

```text
packages/report_engine/lib/src/services/pdf_render_service.dart
```

Typical use:

```dart
final bytes = await PdfRenderService().render(templateJson, data);
```

The service:

1. loads bundled fonts
2. parses the shared template
3. resolves runtime data
4. selects thermal or paged rendering
5. converts millimeters to PDF points
6. builds tables/text/barcodes
7. returns PDF bytes

Bundled Thai fonts:

```text
packages/report_engine/assets/fonts/
├── NotoSansThai-Regular.ttf
└── NotoSansThai-Bold.ttf
```

Package-aware asset loading allows these fonts to work when `report_engine` is consumed by another Flutter application.

## 6. Thermal PDF

For `paper.type == 'thermal'`, width comes from `paper.widthMm` and the page uses automatic content height.

Regression coverage now protects both supported receipt widths:

```text
80mm
58mm
```

The tests validate stable PDF properties rather than raw byte identity:

- `%PDF-` header
- `%%EOF`
- page-object count
- `/MediaBox` page width

This catches accidental paper-width regressions without depending on mutable PDF metadata.

## 7. Paged/A4 PDF

Paged documents use `pw.MultiPage`. A4 templates use `PdfPageFormat.a4`.

The renderer also generates a footer containing print time and page number. Because print time is dynamic, whole-file PDF byte equality is intentionally not used as the regression strategy.

Phase 4 regression tests cover:

- A4 width/height through `/MediaBox`
- invoice table with more than 25 rows
- multi-page pagination
- Thai A4 invoice with Thai table labels and rows

## 8. Tables

Table column metadata from Designer is honored by the PDF renderer:

```json
{
  "key": "price",
  "label": "Price",
  "width": 2,
  "alignment": "right"
}
```

Column widths are converted to flex weights and alignments are applied per column.

## 9. System printing facade

File:

```text
packages/report_engine/lib/src/printer/printer_service.dart
```

`FlutterReportPrinter` is the high-level PDF/system-printer facade. It covers PDF generation, preview/share, system printing, and system-printer listing through the `printing` package.

System printing and raw ESC/POS thermal printing are separate paths.

---

# ESC/POS STACK

## 10. Architectural boundary

The printer stack is intentionally layered:

```text
Template + data
      ↓
Rendering
      ↓
ESC/POS bytes
      ↓
Transport
      ↓
Physical printer
```

Optional hardware operations sit beside transport:

```text
CutterCapability
CashDrawerCapability
```

Core rule:

> Rendering produces bytes. Transport sends bytes. Hardware capabilities perform device-specific operations.

`PdfRenderService` does not issue printer hardware commands, and `EscPosRenderer` does not implicitly cut paper.

## 11. `EscPosRenderer`

File:

```text
packages/report_engine/lib/src/printer/rendering/esc_pos_renderer.dart
```

Responsibilities:

- convert template + data into ESC/POS bytes
- resolve dynamic fields
- render text, lines, tables, QR and barcode content
- choose Thai code-page or raster strategy
- render quick receipts

Non-responsibilities:

- Bluetooth connection lifecycle
- USB/network connection lifecycle
- Sunmi service binding
- cutter commands
- cash-drawer commands

## 12. Thai encoding configuration

Core strategies:

```dart
enum ThaiEncoding {
  tis620,
  cp874,
  rasterImage,
}
```

Valid public construction paths are intentionally constrained:

```dart
EscPosEncodingConfig.tis620(codeTable: printerSpecificTable)
EscPosEncodingConfig.cp874(codeTable: printerSpecificTable)
EscPosEncodingConfig.raster()
```

A TIS-620 or CP874 configuration cannot be constructed without an explicit code-table number. This invariant is structural and remains valid in release builds where Dart assertions are disabled.

Code-table numbers are printer-specific. Do not treat a table number verified on one ESC/POS clone as a universal default.

## 13. `EscPosTextEncoder`

The text encoder is pure conversion logic and has no transport dependency.

Code-page paths emit the printer code-table selection followed by encoded bytes. Tests cover:

```text
กุ้ง
น้ำ
ยอดรวม
mixed Thai/English
Thai numerals
CP874 extensions
unsupported-character replacement
```

Raster mode is handled by the rasterizer instead of pretending raster content is a single-byte character encoding.

## 14. Rasterized Thai

File:

```text
packages/report_engine/lib/src/printer/rendering/esc_pos_rasterizer.dart
```

Flow:

```text
Thai text
   ↓
TextPainter + bundled Noto Sans Thai
   ↓
RGBA image
   ↓
monochrome threshold
   ↓
bit packing
   ↓
ESC/POS raster bytes
```

Raster output is the safest fallback when a printer's Thai code-page mapping is unknown or unreliable.

## 15. Quick-receipt 8/2/2 layout

Quick receipts preserve these semantic columns:

```text
item name = 8 units, left aligned
quantity  = 2 units, centered
price     = 2 units, right aligned
```

The legacy generator, code-page renderer, and raster renderer all preserve equivalent layout semantics. This avoids long item names pushing quantity/price into arbitrary positions.

## 16. Transport contract

File:

```text
packages/report_engine/lib/src/printer/transport/esc_pos_transport.dart
```

```dart
abstract interface class EscPosTransport {
  Future<void> send(List<int> bytes);
}
```

Current implementations include BLE in core and Sunmi embedded transport in the companion package.

Future adapters can implement the same contract for:

- Bluetooth Classic
- USB
- TCP/network
- other embedded printer SDKs

## 17. BLE boundary

Core BLE support uses `flutter_blue_plus`.

Important limitation:

> `flutter_blue_plus` supports Bluetooth Low Energy only. It does not make Bluetooth Classic thermal printers compatible.

Bluetooth Classic devices require a different adapter.

## 18. `EscPosPrinterService`

The service orchestrates rendering, transport, and optional hardware capabilities.

Conceptually:

```text
parse template
   ↓
EscPosRenderer
   ↓
bytes
   ↓
EscPosTransport.send
   ↓
optional CutterCapability.cutPaper
```

When cutting is requested but no cutter capability is available, the service fails before sending the payload. This prevents a partial-success state where printing occurred but the requested hardware operation could never be completed.

---

# DISCOVERY

## 19. Unified printer model

Core connection types:

```dart
enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}
```

`UnifiedPrinter` exposes domain-safe fields such as ID, name, connection type, and metadata. Raw plugin objects are deliberately not exposed.

## 20. Discovery composition

Discovery sources implement a common interface and are composed by `PrinterDiscoveryService`.

Current built-in sources:

- system printer discovery
- Bluetooth LE discovery

The service provides:

- source exception isolation
- blank-ID filtering
- deterministic IDs where available
- deduplication
- deterministic ordering
- immutable results
- optional additional discovery sources

The enum values `usb` and `network` are extension points; they do not imply built-in generic USB/TCP discovery already exists.

---

# HARDWARE CAPABILITIES

## 21. Cutter and cash drawer

Core contracts:

```dart
abstract interface class CutterCapability {
  Future<void> cutPaper();
}

abstract interface class CashDrawerCapability {
  Future<void> openCashDrawer();
  Future<bool> isCashDrawerOpen();
}
```

Capability presence is explicit. Adapters should implement only operations known to be supported by the target hardware profile.

---

# SUNMI COMPANION PACKAGE

## 22. Package boundary

Sunmi support lives in:

```text
packages/report_engine_sunmi
```

This isolates the Android-only `sunmi_printer_plus` dependency from cross-platform core.

## 23. `SunmiPrinterBridge`

The bridge wraps plugin operations such as:

```text
printEscPos
cutPaper
openDrawer
isDrawerOpen
getId
getType
getVersion
rebindPrinter
```

Tests inject a fake bridge so adapter behavior can be exercised without physical Sunmi hardware.

## 24. `SunmiHardwareProfile`

Default behavior is print-only.

Optional hardware is exposed only when the host provides a verified profile:

```dart
const SunmiHardwareProfile(
  supportsCutter: true,
  supportsCashDrawer: false,
)
```

The adapter factory returns implementations whose runtime interfaces match the supplied profile. Unsupported cutter/drawer interfaces are therefore absent rather than methods that fail after use.

This profile is software knowledge supplied by the host. It does not replace physical verification.

---

# PHASE 4 HARDENING

## 25. CI quality gates

`.github/workflows/ci.yml` uses Flutter **3.32.7** and keeps the six-platform Designer build matrix.

Quality jobs now cover four scopes independently:

```text
report_engine
  pub get
  format check
  analyze
  tests + coverage

report_engine_sunmi
  pub get
  format check
  analyze
  tests

designer
  pub get
  format check
  analyze
  tests + coverage

report_engine/example
  pub get
  format check
  analyze
  tests
  Android debug APK build
```

Designer build jobs remain:

```text
Web release
Android APK
Linux release
Windows release
macOS release
iOS simulator
```

The companion Sunmi package has its own quality gate because it has platform-specific dependencies and must not depend on incidental validation performed by core or Designer jobs.

## 26. Rendering regression strategy

File:

```text
packages/report_engine/test/pdf_render_service_test.dart
```

The regression suite protects:

- Thermal 80mm geometry
- Thermal 58mm geometry
- A4 geometry
- A4 invoice pagination with more than 25 rows
- Thai A4 invoice rendering

Stable assertions include:

```text
PDF signature/footer
page-object count
/MediaBox dimensions
pagination behavior
minimum output-size sanity for embedded Thai-font output
```

Raw PDF byte equality is deliberately avoided because runtime timestamps and PDF object/metadata details may change without changing the rendered document semantics.

## 27. Printer compatibility evidence

The compatibility matrix lives in:

```text
docs/PRINTER_COMPATIBILITY.md
```

It separates four concepts that must not be conflated:

```text
Implemented software
Automated coverage
Emulator/simulator validation
Physical hardware verification
```

Candidate hardware currently documented includes:

```text
XP-80
XP-58
Epson TM-T88V
Sunmi V2
```

Until real-device evidence is recorded, each remains:

```text
NEEDS PHYSICAL VERIFICATION
```

---

# VALIDATION AND DEBUGGING

## 28. Recommended validation order

For core changes:

```bash
cd packages/report_engine
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For Sunmi changes:

```bash
cd packages/report_engine_sunmi
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For Designer changes:

```bash
cd apps/designer
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For the engine example:

```bash
cd packages/report_engine/example
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## 29. Debug by layer

When printer output is wrong, identify the failing layer first:

```text
wrong resolved value
→ resolver/template

wrong PDF layout
→ PdfRenderService

wrong ESC/POS bytes
→ encoder/renderer/rasterizer

bytes correct but not delivered
→ transport

printer missing from list
→ discovery source

cut/drawer unsupported
→ capability/profile

works in tests but not on device
→ physical compatibility investigation
```

Do not solve transport problems by adding logic to rendering, and do not declare model compatibility based solely on unit tests.

---

# RELEASE BOUNDARY

## 30. What is software-validated

The project has software coverage for:

- PDF generation
- Thai PDF fonts
- thermal and A4 geometry
- multi-page invoice behavior
- Thai invoice output
- ESC/POS TIS-620/CP874 conversion
- Thai raster fallback
- quick-receipt layout
- transport abstraction
- unified discovery behavior
- Sunmi adapter behavior through fake bridge tests
- optional hardware capability ordering
- Designer template persistence/editing workflows

## 31. What still requires hardware evidence

Software validation is not physical printer validation.

Before claiming a model as physically supported, record real-device evidence according to `docs/PRINTER_COMPATIBILITY.md`.

In particular, do not infer:

- an XP-series printer's Thai code-table number
- Bluetooth Classic compatibility from BLE support
- a Sunmi model's cutter/drawer support from brand alone
- an Epson model's raw USB/network compatibility from OS system-printer support

Those remain hardware/integration facts that must be verified on the actual target environment.
