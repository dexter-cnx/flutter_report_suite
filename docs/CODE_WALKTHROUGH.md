# Code Walkthrough

This document explains the current production architecture of `flutter_report_suite`, with emphasis on the Designer UI migration, shared template contract, PDF/ESC-POS rendering boundaries, persistence, hardware adapters, and CI gates.

## 1. Repository map

```text
flutter_report_suite/
├── .github/workflows/ci.yml
├── apps/
│   └── designer/
│       ├── assets/templates/
│       ├── lib/
│       │   ├── controllers/
│       │   ├── design_system/
│       │   ├── pages/
│       │   └── services/
│       └── test/
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
    ├── design/
    ├── PROJECT_HANDOFF.md
    ├── CODE_WALKTHROUGH.md
    └── PRINTER_COMPATIBILITY.md
```

Dependency direction:

```text
apps/designer
      ↓
report_engine
      ↑
report_engine_sunmi
```

`report_engine` stays cross-platform. `report_engine_sunmi` is an optional Android integration so Sunmi dependencies do not contaminate Web, desktop, or iOS consumers.

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
Designer presentation = millimeters × canvas scale × zoom
PDF geometry          = millimeters → PDF points
```

This invariant is critical: changing Designer zoom must never mutate persisted geometry.

The template model supports static text, dynamic text, lines, tables, QR codes, and barcodes. PDF and ESC/POS rendering consume the same contract.

## 3. Value resolution

File:

```text
packages/report_engine/lib/src/services/report_value_resolver.dart
```

The resolver supports nested maps, list indexes, interpolation, primitive values, missing values, and invalid indexes.

Typical expressions:

```dart
resolver.resolve('{{shop.name}}', data);
resolver.resolve('{{items.0.name}}', data);
resolver.resolveText('Invoice {{invoiceNo}}', data);
```

Centralizing this behavior prevents PDF and ESC/POS output from interpreting bindings differently.

## 4. Designer document state

File:

```text
apps/designer/lib/controllers/designer_document_controller.dart
```

`DesignerDocumentController` owns document behavior rather than visual styling. It is responsible for operations such as:

- selection
- add/delete element
- move/resize
- interactive drag transactions
- 5 mm snapping
- zoom state
- paper configuration
- table-column metadata
- undo/redo history
- loading/replacing a template

The UI calls controller operations; it should not duplicate millimeter math or history logic.

Grouped drag interactions follow this pattern:

```text
pointer down
→ beginInteraction()
→ moveSelectedInteractive(...) × N
→ endInteraction()
→ one undo transaction
```

That prevents every pointer delta from becoming a separate undo step.

## 5. Designer UI design system

The normalized Flutter UI system lives in:

```text
apps/designer/lib/design_system/
├── design_system.dart
├── designer_colors.dart
├── designer_typography.dart
├── designer_spacing.dart
├── designer_radius.dart
├── designer_layout.dart
├── designer_elevation.dart
├── designer_theme.dart
├── designer_controls.dart
├── designer_shell.dart
└── canvas_primitives.dart
```

The design handoff is normalized in `docs/design/`; generated Stitch HTML is reference material, while the normalized Markdown specs and Flutter tokens are the implementation source of truth.

Canonical tokens include:

```text
primary             #6366F1
toolbar height       56 px
left panel width    264 px
inspector width     320 px
status bar height    32 px
selection border      1 px
resize handle         8 px
```

`DesignerTheme.light()` applies the shared theme instead of each page creating independent Material styling.

## 6. Shared Designer controls

`designer_controls.dart` contains reusable editing primitives such as:

```text
ToolbarButton
PanelHeader
InspectorSection
PropertyInput
NumberPropertyInput
PropertyDropdown
PropertyToggle
ZoomControl
InlineAlert
```

Property text inputs are designed to stay synchronized with model updates such as selection changes, undo, and document loading. Compact controls use compact-specific text metrics/padding so the 28 px control contract does not clip text.

The Designer does not force a non-bundled Inter font. Platform/default typography remains in use until a redistribution-safe font asset is explicitly bundled and registered.

## 7. Live `DesignerPage` composition

File:

```text
apps/designer/lib/pages/designer_page.dart
```

The desktop workspace now uses reusable design-system primitives:

```text
DesignerAppShell
├── toolbar
├── Elements panel
├── CanvasViewport
│   ├── CanvasRuler (vertical)
│   └── canvas column
│       ├── CanvasRuler (horizontal)
│       └── CanvasPage
│           ├── CanvasGuideOverlay
│           └── CanvasSelectionOverlay × element
├── Inspector
└── DesignerStatusBar
    └── ZoomControl
```

The page still delegates schema/state behavior to `DesignerDocumentController`; the migration is primarily presentation and composition.

### Responsive behavior

The fixed desktop shell is used at widths `>= 1280`.

Below 1280 px, the page uses the compact composition instead of reserving fixed 264 px + 320 px side panels. This keeps the canvas as the priority surface in the 1024–1279 range and on smaller screens.

The entire custom workspace is wrapped in `SafeArea`, because replacing a platform `AppBar` with a custom toolbar means the framework no longer automatically protects the title/actions from mobile status bars or notches.

### Toolbar behavior

The custom toolbar preserves existing actions:

```text
Undo
Redo
Preview PDF
Template actions
```

Template actions continue to expose:

```text
New
Save
Save As
Rename
Load
Duplicate
Delete
Import JSON
Export JSON
Share JSON
View JSON
```

### Keyboard behavior

Existing shortcuts remain controller-backed:

```text
Ctrl/Cmd + Z          undo
Ctrl/Cmd + Shift + Z  redo
Delete/Backspace      delete selection
Arrow keys            nudge 1 mm
Shift + Arrow keys    nudge 5 mm
```

The design spec may describe future shortcuts, but UI/documentation should not claim unsupported shortcuts as implemented.

## 8. Canvas primitives

File:

```text
apps/designer/lib/design_system/canvas_primitives.dart
```

### `CanvasViewport`

Owns workspace presentation and pan/overflow behavior. It does not own report geometry.

### `CanvasPage`

Receives explicit scaled width/height. Its visual border is painted as an overlay so the border does not reduce the printable child's coordinate space.

For example, a requested 240 × 600 canvas remains a full 240 × 600 layout region for its child.

### `CanvasRuler`

Ruler labels are expressed in millimeters and positioned with the current scale. Ruler rendering is presentation only; persisted coordinates remain millimeters.

### `CanvasGuideOverlay`

Draws visual center guides independently from report elements.

### `CanvasSelectionOverlay`

The selected child remains non-positioned inside the overlay so the child establishes the overlay size. Only resize handles are positioned. This prevents a selected element from expanding to the remaining `Stack` constraints and intercepting neighboring elements.

## 9. Elements and Inspector panels

The left side uses normalized `PanelHeader` and `PropertyDropdown` components for Elements/Document sections while retaining the existing add-element commands.

The right Inspector has moved into the canonical 320 px shell. The current migration intentionally preserves existing field behavior; deeper conversion of every inspector field into `PropertyInput`, `NumberPropertyInput`, `PropertyToggle`, and structured `InspectorSection` components is the next UI phase.

Table column editing remains model-compatible with existing metadata. Stitch-only concepts such as merged cells or richer pagination must not be exposed until the report model and renderer support them.

## 10. Template lifecycle

`TemplateStorageService` provides local Hive persistence.

Designer lifecycle:

```text
Create
→ Edit
→ Save / Save As
→ Load
→ Rename / Duplicate / Delete
→ Export / Import / Share JSON
```

Built-in gallery templates are treated as immutable sources; opening one creates an editable working copy.

---

# PDF STACK

## 11. `PdfRenderService`

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
6. builds text/tables/barcodes
7. returns PDF bytes

Bundled Thai fonts live under:

```text
packages/report_engine/assets/fonts/
├── NotoSansThai-Regular.ttf
└── NotoSansThai-Bold.ttf
```

Package-aware asset loading keeps Thai rendering available when `report_engine` is consumed by another Flutter application.

## 12. Thermal and paged PDF

Thermal pages use configured physical width with automatic content height. Regression tests protect both 80 mm and 58 mm receipt geometry.

Paged/A4 output uses `pw.MultiPage`. Tests cover page geometry, long invoice tables, pagination, and Thai invoice content.

Stable regression assertions target PDF structure/geometry rather than raw whole-file byte equality because timestamps and object metadata may legitimately change.

## 13. Tables

Designer table metadata is consumed by PDF rendering:

```json
{
  "key": "price",
  "label": "Price",
  "width": 2,
  "alignment": "right"
}
```

Widths become flex weights and alignment is applied per column.

## 14. System printing facade

`FlutterReportPrinter` is the high-level PDF/system-printer facade. It covers PDF generation, preview/share, system printing, and system printer listing through the `printing` package.

System printing and raw ESC/POS printing are separate paths.

---

# ESC/POS STACK

## 15. Architectural boundary

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

Optional operations are explicit capabilities:

```text
CutterCapability
CashDrawerCapability
```

Rendering produces bytes. Transport sends bytes. Hardware capabilities perform device-specific operations.

## 16. `EscPosRenderer`

File:

```text
packages/report_engine/lib/src/printer/rendering/esc_pos_renderer.dart
```

Responsibilities include resolving fields and rendering text, lines, tables, QR/barcode content, quick receipts, and Thai encoding/raster strategies.

It does not own Bluetooth connection lifecycle, Sunmi service binding, cutter commands, or drawer commands.

## 17. Thai encoding

Supported configuration paths include:

```dart
EscPosEncodingConfig.tis620(codeTable: printerSpecificTable)
EscPosEncodingConfig.cp874(codeTable: printerSpecificTable)
EscPosEncodingConfig.raster()
```

TIS-620/CP874 require an explicit printer code-table number. Printer table numbers are firmware-specific and must not be generalized from one device.

Rasterized Thai uses Flutter text shaping with bundled Noto Sans Thai, converts the rendered image to monochrome pixels, packs bits, and emits ESC/POS raster bytes. This is the safest fallback when code-page mapping is unknown.

## 18. Quick receipt layout

Quick receipts preserve semantic 8/2/2 proportions:

```text
item name = 8 units, left
quantity  = 2 units, center
price     = 2 units, right
```

Equivalent semantics are maintained across legacy, code-page, and raster paths.

## 19. Transport contract

```dart
abstract interface class EscPosTransport {
  Future<void> send(List<int> bytes);
}
```

Core currently contains BLE transport support. The companion Sunmi package supplies embedded transport. Other transports can implement the same contract.

Important limitation: `flutter_blue_plus` is BLE only; it does not provide Bluetooth Classic support.

## 20. `EscPosPrinterService`

The service orchestrates template parsing, rendering, transport, and optional capabilities.

If a requested cutter operation is unavailable, the service fails before sending the print payload. This avoids a partial-success state where printing succeeds but a mandatory hardware action cannot run.

---

# DISCOVERY AND HARDWARE

## 21. Unified printer model

```dart
enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}
```

`UnifiedPrinter` exposes domain-safe identity/connection metadata instead of raw plugin objects.

`PrinterDiscoveryService` composes discovery sources, isolates source failures, filters invalid IDs, deduplicates, orders results deterministically, and returns immutable output.

The presence of enum values such as `usb` or `network` is an extension point and does not imply generic built-in raw USB/TCP discovery.

## 22. Cutter and cash drawer

Core capability contracts are explicit:

```dart
abstract interface class CutterCapability {
  Future<void> cutPaper();
}

abstract interface class CashDrawerCapability {
  Future<void> openCashDrawer();
  Future<bool> isCashDrawerOpen();
}
```

Adapters implement only capabilities known to be supported by their verified hardware profile.

---

# SUNMI COMPANION PACKAGE

## 23. Package boundary

Sunmi support lives in:

```text
packages/report_engine_sunmi
```

`SunmiPrinterBridge` wraps plugin operations and is injectable, allowing adapter tests to run against a fake bridge without physical hardware.

`SunmiHardwareProfile` defaults to print-only. Cutter/drawer capability interfaces appear only when the host supplies a profile that enables them.

A software profile is not a substitute for real hardware validation.

---

# CI AND HARDENING

## 24. CI quality gates

`.github/workflows/ci.yml` uses Flutter **3.32.7**.

Independent quality jobs cover:

```text
report_engine
  pub get
  format
  analyze
  tests + coverage
  pub publish --dry-run

report_engine_sunmi
  pub get
  format
  analyze
  tests

designer
  pub get
  format
  analyze
  tests + coverage

report_engine/example
  pub get
  format
  analyze
  tests
  Android debug APK
```

Designer build jobs cover:

```text
Web release
Android APK
Linux release
Windows release
macOS release
iOS simulator
```

When Designer formatting fails, CI formats `lib`/`test`, prints the diff, and uploads a `formatted-designer` artifact. This makes formatter-only failures reproducible using the exact Flutter/Dart version used by CI.

## 25. Designer regression coverage

Relevant tests include:

```text
apps/designer/test/design_system_test.dart
apps/designer/test/designer_shell_canvas_test.dart
apps/designer/test/designer_page_test.dart
apps/designer/test/designer_document_controller_test.dart
```

Coverage protects:

- normalized shell dimensions
- printable CanvasPage dimensions
- ruler marks
- selection handle count/size behavior
- selected child sizing
- live DesignerPage use of shell/canvas primitives
- compact layout below 1280 px
- SafeArea presence for the custom toolbar
- add/select/edit behavior
- table-column editor
- JSON schema visibility
- undo/history controller behavior

## 26. PDF regression strategy

`packages/report_engine/test/pdf_render_service_test.dart` protects thermal 80 mm, thermal 58 mm, A4 geometry, multi-page invoice pagination, and Thai A4 rendering.

Stable assertions include PDF signature/footer, page count, `/MediaBox` dimensions, pagination behavior, and output-size sanity for embedded Thai fonts.

## 27. Printer compatibility evidence

`docs/PRINTER_COMPATIBILITY.md` separates:

```text
Implemented software
Automated coverage
Emulator/simulator validation
Physical hardware verification
```

Do not infer physical compatibility from unit tests or brand names.

---

# VALIDATION AND DEBUGGING

## 28. Recommended validation order

Core:

```bash
cd packages/report_engine
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Designer:

```bash
cd apps/designer
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Sunmi:

```bash
cd packages/report_engine_sunmi
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Example:

```bash
cd packages/report_engine/example
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## 29. Debug by layer

```text
wrong resolved value
→ resolver/template

wrong Designer geometry/history
→ DesignerDocumentController

wrong Designer visual composition
→ design_system / DesignerPage

wrong PDF layout
→ PdfRenderService

wrong ESC/POS bytes
→ encoder/renderer/rasterizer

bytes correct but not delivered
→ transport

printer missing
→ discovery source

cut/drawer unsupported
→ capability/profile

works in tests but not on device
→ physical compatibility investigation
```

Do not solve transport problems in rendering code, and do not solve UI composition problems by changing persisted report geometry.

---

# RELEASE BOUNDARY

## 30. Software-validated areas

The project has automated/software coverage for PDF generation, Thai PDF fonts, thermal/A4 geometry, pagination, ESC/POS Thai conversion/raster fallback, quick-receipt layout, transport abstractions, discovery composition, Sunmi adapter behavior through fakes, template persistence/editing, Designer history behavior, and the normalized shell/canvas UI contracts.

## 31. Hardware evidence still matters

Before claiming a printer model as physically supported, record real-device evidence according to `docs/PRINTER_COMPATIBILITY.md`.

Do not infer:

- XP-series Thai code tables
- Bluetooth Classic compatibility from BLE support
- Sunmi cutter/drawer support from brand alone
- Epson raw USB/network compatibility from OS printer support

Those are hardware/integration facts and require validation on the actual target environment.
