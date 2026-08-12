# Code Walkthrough

This document explains the current `flutter_report_suite` architecture after the reviewed Phase 3 printer-engine work.

It covers:

- template contract and Designer relationship
- PDF rendering
- Thai ESC/POS encoding
- raster fallback
- quick-receipt layout
- transport abstraction
- unified discovery
- Sunmi companion package
- optional hardware capabilities
- validation and debugging boundaries

---

## 1. Repository map

```text
flutter_report_suite/
├── .github/workflows/ci.yml
├── apps/
│   └── designer/
│       ├── android/ ios/ web/ macos/ windows/ linux/
│       ├── assets/templates/
│       ├── lib/
│       └── test/
├── packages/
│   ├── report_engine/
│   │   ├── assets/fonts/
│   │   ├── assets/templates/
│   │   ├── example/
│   │   ├── lib/
│   │   │   ├── report_engine.dart
│   │   │   └── src/
│   │   │       ├── models/
│   │   │       ├── services/
│   │   │       └── printer/
│   │   │           ├── capabilities/
│   │   │           ├── discovery/
│   │   │           ├── encoding/
│   │   │           ├── rendering/
│   │   │           ├── transport/
│   │   │           ├── printer_service.dart
│   │   │           └── esc_pos_printer_service.dart
│   │   └── test/
│   └── report_engine_sunmi/
│       ├── lib/
│       │   ├── report_engine_sunmi.dart
│       │   └── src/
│       │       ├── sunmi_printer_adapter.dart
│       │       └── sunmi_printer_bridge.dart
│       └── test/
└── docs/
    ├── PROJECT_HANDOFF.md
    ├── CODE_WALKTHROUGH.md
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

`report_engine` is the cross-platform core. `report_engine_sunmi` is an optional Android-specific integration package.

---

## 2. Architectural rule

The printer stack deliberately separates four concerns:

```text
Template + data
      ↓
Rendering
      ↓
ESC/POS bytes
      ↓
Transport
      ↓
Physical device
```

Optional physical operations live beside transport rather than inside rendering:

```text
CutterCapability
CashDrawerCapability
```

The key rule is:

> Rendering produces bytes. Transport sends bytes. Hardware capabilities perform device-specific operations.

`PdfRenderService` never cuts paper or opens a drawer.

---

## 3. Public engine API

Canonical import:

```dart
import 'package:report_engine/report_engine.dart';
```

The public core API exports:

- `ReportTemplate`
- `ReportValueResolver`
- `PdfRenderService`
- `TemplateStorageService`
- `FlutterReportPrinter`
- `EscPosPrinterService`
- `EscPosRenderer`
- `EscPosRasterizer`
- `EscPosTransport`
- Thai encoding configuration
- unified printer discovery
- hardware capability contracts

Sunmi is imported separately:

```dart
import 'package:report_engine_sunmi/report_engine_sunmi.dart';
```

This prevents an Android-only dependency from leaking into Web/Desktop/iOS consumers of core.

---

## 4. Shared template contract

Primary model:

```text
packages/report_engine/lib/src/models/report_template.dart
```

The shared contract consists of:

```text
ReportTemplate
PaperConfig
ReportElement
```

Geometry is persisted in physical millimeters:

```text
model geometry = millimeters
Designer screen geometry = millimeters × zoom
PDF geometry = millimeters → PDF points
```

The same template JSON can drive both PDF and ESC/POS output.

Example dynamic field:

```json
{
  "id": "shop-name",
  "type": "dynamic_text",
  "key": "{{shop.name}}",
  "x": 5,
  "y": 5,
  "w": 70,
  "h": 8,
  "style": {
    "fontSize": 14,
    "bold": true,
    "align": "center"
  }
}
```

---

## 5. Value resolution

File:

```text
packages/report_engine/lib/src/services/report_value_resolver.dart
```

Examples:

```dart
const resolver = ReportValueResolver();

resolver.resolve('{{shop.name}}', data);
resolver.resolve('{{items.0.name}}', data);
resolver.resolveText('Invoice {{invoiceNo}}', data);
```

Supported behavior includes:

- nested maps
- list indexes
- interpolation
- missing values
- null values
- invalid indexes
- numeric and boolean values

PDF and ESC/POS share the same resolver so expression semantics do not drift between output channels.

---

## 6. PDF rendering

File:

```text
packages/report_engine/lib/src/services/pdf_render_service.dart
```

Typical call:

```dart
final bytes = await PdfRenderService().render(templateJson, data);
```

The renderer:

1. parses the template
2. resolves runtime data
3. loads bundled fonts
4. converts millimeters to PDF units
5. renders thermal or paged documents
6. returns `Uint8List`

Bundled Thai fonts:

```text
packages/report_engine/assets/fonts/
├── NotoSansThai-Regular.ttf
└── NotoSansThai-Bold.ttf
```

Package-aware asset lookup allows the fonts to work when the package is consumed from another Flutter app.

---

## 7. System printing facade

File:

```text
packages/report_engine/lib/src/printer/printer_service.dart
```

`FlutterReportPrinter` is the high-level PDF/system-printer facade.

```dart
final printer = FlutterReportPrinter();
final bytes = await printer.generatePdf(
  templateJson: template,
  data: data,
);
```

Other operations cover preview, share, direct system printing, and printer listing through the `printing` package.

This path is separate from raw ESC/POS thermal printing.

---

# ESC/POS STACK

## 8. `EscPosRenderer`

File:

```text
packages/report_engine/lib/src/printer/rendering/esc_pos_renderer.dart
```

Responsibilities:

- convert a `ReportTemplate` + data into ESC/POS bytes
- resolve dynamic fields
- render text/lines/tables/QR/barcode
- select code-page or raster Thai strategy
- render quick receipts

Non-responsibilities:

- Bluetooth connection
- USB/network connection
- Sunmi service binding
- cut
- cash drawer

Example:

```dart
final bytes = await EscPosRenderer().renderTemplate(
  template: template,
  data: data,
  encodingConfig: const EscPosEncodingConfig.raster(),
);
```

---

## 9. Thai encoding configuration

Files:

```text
packages/report_engine/lib/src/printer/encoding/
├── thai_encoding.dart
├── esc_pos_encoding_config.dart
└── esc_pos_text_encoder.dart
```

Strategies:

```dart
enum ThaiEncoding {
  tis620,
  cp874,
  rasterImage,
}
```

### Important invariant

Code-page encodings cannot exist without a code-table number.

The reviewed public API intentionally exposes only:

```dart
EscPosEncodingConfig.tis620(codeTable: 26)
EscPosEncodingConfig.cp874(codeTable: 30)
EscPosEncodingConfig.raster()
```

There is no public generic constructor that allows this invalid state:

```text
CP874/TIS-620 + codeTable == null
```

This matters because Dart `assert` statements disappear in release builds. The invariant is therefore enforced structurally by the API instead of only through a debug assertion.

### TIS-620

```dart
const encoding = EscPosEncodingConfig.tis620(
  codeTable: printerSpecificTable,
);
```

### CP874

```dart
const encoding = EscPosEncodingConfig.cp874(
  codeTable: printerSpecificTable,
);
```

The table number remains printer-specific because ESC/POS clones do not assign Thai tables consistently.

### Raster

```dart
const encoding = EscPosEncodingConfig.raster();
```

Raster avoids printer-side Thai character mapping completely.

Tests cover:

```text
กุ้ง
น้ำ
ยอดรวม
mixed Thai/English
Thai numerals
CP874 punctuation extensions
```

---

## 10. `EscPosTextEncoder`

`EscPosTextEncoder` is pure byte conversion logic with no transport dependency.

For code-page output it emits:

```text
ESC t n
encoded payload
LF
```

Responsibilities include:

- ASCII pass-through
- Thai TIS-620 mappings
- CP874 extension bytes
- replacement byte for unsupported characters
- code-table range validation

Raster mode intentionally throws from this encoder because raster rendering belongs to the rasterizer, not the single-byte encoder.

---

## 11. Rasterized Thai

File:

```text
packages/report_engine/lib/src/printer/rendering/esc_pos_rasterizer.dart
```

`FlutterEscPosRasterizer` flow:

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
ESC/POS GS v 0 raster command
```

This is the fallback for printers with unknown or unreliable Thai code pages.

### Raster columns

Quick receipts need alignment, not just readable Thai text. The rasterizer therefore also supports measured column rendering so item/quantity/price columns retain their semantic widths and alignment.

---

## 12. Quick-receipt 8/2/2 layout

Phase 3 review caught an important regression: concatenating item name, quantity, and price into one string loses the original column layout.

The reviewed implementation preserves:

```text
item name  = 8 units, left
quantity   = 2 units, center
price      = 2 units, right
```

Legacy path:

```text
Generator.row(...)
```

Code-page path:

```text
fixed-width 8/2/2 equivalent
```

Raster path:

```text
measured 8/2/2 column rectangles
```

Why this matters:

- prices stay right-aligned
- quantity stays centered
- long names are constrained to the item column instead of pushing price to an arbitrary printer line boundary

This is covered by regression tests.

---

## 13. ESC/POS transport

Contract:

```text
packages/report_engine/lib/src/printer/transport/esc_pos_transport.dart
```

```dart
abstract interface class EscPosTransport {
  Future<void> send(List<int> bytes);
}
```

Rendering is therefore independent of connection mechanism.

Current implementations include:

- BLE transport in core
- Sunmi embedded transport in companion package

Future adapters can implement the same interface for:

- network TCP
- USB
- Bluetooth Classic
- other embedded printer SDKs

---

## 14. BLE transport

File:

```text
packages/report_engine/lib/src/printer/transport/bluetooth_esc_pos_transport.dart
```

Responsibilities:

- connect
- discover services
- find writable characteristic
- chunk writes
- cleanup/disconnect

Important limitation:

> `flutter_blue_plus` supports Bluetooth Low Energy, not Bluetooth Classic.

Many inexpensive thermal printers use Bluetooth Classic. Those devices need a separate future transport/discovery implementation rather than being treated as BLE-compatible.

---

## 15. `EscPosPrinterService`

File:

```text
packages/report_engine/lib/src/printer/esc_pos_printer_service.dart
```

The service is orchestration, not rendering or transport implementation.

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

If cut is requested without an explicit cutter capability, the service fails before sending the payload. This prevents a receipt from printing successfully and only then discovering that the requested hardware operation is unsupported.

---

# DISCOVERY

## 16. Unified printer model

File:

```text
packages/report_engine/lib/src/printer/discovery/unified_printer.dart
```

```dart
enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}
```

`UnifiedPrinter` contains domain-safe values such as:

```text
id
name
type
metadata
```

Raw plugin objects are intentionally not exposed.

---

## 17. Discovery sources

Contract:

```dart
abstract interface class PrinterDiscoverySource {
  Future<List<UnifiedPrinter>> discover();
}
```

Current sources:

- `SystemPrinterDiscovery`
- `BluetoothPrinterDiscovery`
- `SunmiPrinterAdapter` as an additional embedded source

`PrinterDiscoveryService.discoverAll()`:

- invokes sources independently
- isolates source exceptions
- removes blank IDs
- deduplicates by deterministic ID
- sorts results deterministically
- returns an immutable result

Example:

```dart
final discovery = PrinterDiscoveryService.standard(
  additionalSources: <PrinterDiscoverySource>[sunmi],
);

final printers = await discovery.discoverAll();
```

---

# HARDWARE CAPABILITIES

## 18. Core capability contracts

File:

```text
packages/report_engine/lib/src/printer/capabilities/printer_hardware_capabilities.dart
```

```dart
abstract interface class CutterCapability {
  Future<void> cutPaper();
}

abstract interface class CashDrawerCapability {
  Future<void> openCashDrawer();
  Future<bool> isCashDrawerOpen();
}
```

The design relies on **interface presence** rather than assuming every printer supports every hardware command.

---

# SUNMI

## 19. Why Sunmi is a companion package

Package:

```text
packages/report_engine_sunmi
```

`sunmi_printer_plus` is Android-specific. Keeping it outside `report_engine` preserves the cross-platform dependency boundary of core.

Audit details:

```text
docs/PHASE3_SUNMI_ADAPTER_AUDIT.md
```

---

## 20. `SunmiPrinterBridge`

File:

```text
packages/report_engine_sunmi/lib/src/sunmi_printer_bridge.dart
```

The bridge wraps plugin APIs such as:

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

Tests inject a fake bridge so package behavior can be validated without a physical Sunmi terminal.

---

## 21. `SunmiHardwareProfile`

Phase 3 review established that Sunmi cutter/drawer support must **not** be declared universally.

The safe model is:

```dart
const SunmiHardwareProfile(
  supportsCutter: false,
  supportsCashDrawer: false,
)
```

Default:

```text
print-only
```

A host app enables optional hardware only from its verified device inventory:

```dart
final sunmi = SunmiPrinterAdapter(
  hardwareProfile: const SunmiHardwareProfile(
    supportsCutter: true,
    supportsCashDrawer: false,
  ),
);
```

The adapter factory selects an internal implementation whose runtime type implements only the confirmed interfaces.

Therefore:

```text
unsupported cutter
→ adapter is NOT CutterCapability

unsupported drawer
→ adapter is NOT CashDrawerCapability
```

This is stronger than simply exposing methods that may fail after printing.

---

## 22. Sunmi discovery metadata

Sunmi discovery returns an embedded `UnifiedPrinter`.

Metadata includes capability flags derived from the supplied `SunmiHardwareProfile`, not unconditional `true` values.

Typical fields:

```text
deviceId
type
version
adapter
cutter
cashDrawer
```

These values describe configured/verified software knowledge. They are not a substitute for physical compatibility evidence.

---

# DESIGNER

## 23. Designer relationship

`apps/designer` authors the same template contract consumed by `report_engine`.

Key capabilities after Phase 2:

- Gallery
- built-in templates
- save/load
- import/export/share
- table-column editor
- snap-to-grid
- rulers
- zoom
- undo/redo
- keyboard shortcuts

The dependency rule remains:

> Designer may depend on `report_engine`; `report_engine` must not depend on Designer UI.

---

# TESTING

## 24. Engine test boundaries

Important Phase 3 tests include:

```text
esc_pos_text_encoder_test.dart
esc_pos_renderer_test.dart
esc_pos_printer_service_capability_test.dart
printer_discovery_service_test.dart
```

They cover:

- Thai byte mappings
- CP874 extensions
- raster strategy routing
- no implicit cut command
- quick-receipt column preservation
- discovery composition/dedup/error isolation
- unsupported cut behavior
- `send -> cut` ordering

---

## 25. Sunmi tests

Package tests validate:

- raw byte forwarding
- embedded discovery
- print-only default
- cutter-only profile
- drawer-only profile
- full capability profile
- capability runtime types
- cut/drawer delegation
- service rebind

These are software tests only and do not constitute physical Sunmi certification.

---

## 26. Current validation state

Reviewed Phase 3 head:

```text
97a831c14ab83ff10f93147e7a3942846eb639dd
```

Validated:

- `report_engine` analyze/tests
- `report_engine_sunmi` format/analyze/tests
- Designer analyze/tests
- Web build
- Android build
- Linux build
- Windows build
- macOS build
- iOS simulator build
- PR review threads resolved
- GitHub CI run #49 successful

Still separate:

```text
NEEDS PHYSICAL VERIFICATION
```

for printer-specific Thai rendering and model-specific cutter/drawer compatibility.

---

# DEBUGGING MAP

## 27. Where failures belong

```text
Template/resolver failure
    -> ReportTemplate / ReportValueResolver

PDF failure
    -> PdfRenderService / font assets

Thai code-page bytes wrong
    -> EscPosTextEncoder / EscPosEncodingConfig

Thai raster wrong
    -> FlutterEscPosRasterizer / font loading / threshold

Quick-receipt alignment wrong
    -> EscPosRenderer 8/2/2 layout

Bytes correct but printer receives nothing
    -> EscPosTransport

BLE discovery/connectivity issue
    -> Bluetooth discovery/transport

System printer issue
    -> printing package facade/discovery

Sunmi service issue
    -> SunmiPrinterBridge / rebind

Cut/drawer shown on unsupported Sunmi
    -> SunmiHardwareProfile / adapter factory
```

This separation is intentional: a connection failure should not be debugged inside rendering logic, and a layout regression should not be fixed in transport code.

---

# EXTENSION GUIDE

## 28. Add a new transport

Implement:

```dart
EscPosTransport
```

Example targets:

- TCP/IP
- USB
- Bluetooth Classic

Do not add connection code to `EscPosRenderer`.

## 29. Add a new discovery mechanism

Implement:

```dart
PrinterDiscoverySource
```

Then add it to `PrinterDiscoveryService` composition.

Return `UnifiedPrinter`, not raw plugin types.

## 30. Add optional physical capabilities

Implement core capability interfaces only when the concrete hardware profile truly supports them.

Do not use a universal adapter type that always implements `CutterCapability` or `CashDrawerCapability` when model support varies.

---

# NEXT ARCHITECTURAL WORK

Phase 4 should strengthen CI and documentation without undoing these boundaries.

Highest-priority CI improvement:

> add an explicit `report_engine_sunmi` format/analyze/test job, because Phase 3 required a separate maintainer validation for that companion package.

Also retain the existing Designer multi-platform build matrix and add/retain example APK validation.
