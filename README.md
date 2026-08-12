# Flutter Report Suite

Flutter Report Suite is an offline-first Flutter monorepo for authoring report templates and rendering them to PDF, system printers, and ESC/POS thermal printers across Web, desktop, and mobile.

The runtime contract is shared between the visual Designer and `report_engine`, so templates created in the app can be persisted as JSON and rendered without a backend service.

> Production v1.0.0 is in hardening/release preparation. See [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md) for the execution state and release gates.

## Architecture at a glance

```text
Designer UI
   ↓
DesignerDocumentController
   ↓
ReportTemplate JSON (millimeter geometry)
   ↓
TemplateStorageService / application data
   ↓
report_engine
   ├── PDF / preview / share
   ├── system printing
   └── ESC/POS rendering + transports
          ↓
   optional hardware adapters
```

The project keeps these boundaries explicit:

- UI zoom never changes persisted physical geometry.
- PDF rendering is separate from printer hardware operations.
- ESC/POS rendering is separate from transport.
- Hardware capabilities such as cutter/cash drawer support are explicit and evidence-based.
- Platform-specific integrations such as Sunmi are isolated from cross-platform core.

## Repository structure

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
    ├── CI.md
    ├── CODE_WALKTHROUGH.md
    ├── PRINTER_COMPATIBILITY.md
    └── PROJECT_HANDOFF.md
```

## Packages

### `packages/report_engine`

Reusable rendering and printing core.

Important services and contracts include:

- `ReportTemplate`, `PaperConfig`, `ReportElement`
- `ReportValueResolver`
- `PdfRenderService`
- `FlutterReportPrinter`
- `EscPosRenderer`
- `EscPosPrinterService`
- `EscPosTransport`
- `PrinterDiscoveryService`
- `TemplateStorageService`

Thai PDF rendering uses bundled Noto Sans Thai assets. ESC/POS Thai output supports configurable TIS-620/CP874 paths plus raster fallback when printer code-page behavior is unreliable.

### `packages/report_engine_sunmi`

Optional Android-specific Sunmi integration package. It keeps `sunmi_printer_plus` and embedded-printer behavior out of cross-platform `report_engine` consumers.

### `apps/designer`

Visual report editor backed by the same report schema as `report_engine`.

Current working functionality includes:

- built-in template gallery
- Text, dynamic text, line, table, QR, and barcode elements
- thermal, A4, and custom/report paper configuration
- physical millimeter geometry
- 5 mm snap-to-grid
- center guides and millimeter rulers
- 50%–200% zoom
- drag/move and numeric transform editing
- table column metadata editing
- undo/redo and keyboard nudging
- save/load, Save As, rename, duplicate, delete
- JSON import/export/share
- PDF preview

## Designer UI system

The Designer is being migrated from ad-hoc Material layout to a normalized workspace derived from the Google Stitch design handoff.

The implementation source of truth is under `docs/design/`:

- [DESIGN_SYSTEM.md](docs/design/DESIGN_SYSTEM.md)
- [COMPONENT_SPEC.md](docs/design/COMPONENT_SPEC.md)
- [INTERACTION_SPEC.md](docs/design/INTERACTION_SPEC.md)
- [SCREEN_MAPPING.md](docs/design/SCREEN_MAPPING.md)
- [IMPLEMENTATION_PLAN.md](docs/design/IMPLEMENTATION_PLAN.md)

The Flutter design system lives in:

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

Canonical desktop dimensions are:

```text
Toolbar       56 px
Elements      264 px
Inspector     320 px
Status bar     32 px
Selection      1 px primary border
Resize handle  8 px
```

The live `DesignerPage` now uses the shared shell/canvas primitives rather than duplicating these visual contracts inline:

```text
DesignerAppShell
├── toolbar
├── Elements panel
├── CanvasViewport
│   ├── CanvasRuler
│   ├── CanvasPage
│   ├── CanvasGuideOverlay
│   └── CanvasSelectionOverlay
├── Inspector
└── DesignerStatusBar / ZoomControl
```

For widths below 1280 px the fixed desktop side-panel shell is not used; the canvas receives priority and the panels move to the compact layout. The workspace is wrapped in `SafeArea` so mobile status bars/notches do not overlap the custom toolbar.

## Template model

Geometry is stored independently from UI zoom:

```text
stored geometry       = millimeters
Designer presentation = millimeters × canvas scale × zoom
PDF geometry          = millimeters → PDF points
```

Typical runtime expressions:

```text
{{shop.name}}
{{customer.address.city}}
{{items.0.name}}
```

Missing values degrade safely instead of breaking the complete report.

## Quick start

Production reference toolchain: **Flutter 3.32.7**.

### Report engine

```bash
cd packages/report_engine
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

### Designer

```bash
cd apps/designer
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run -d chrome
```

### Sunmi adapter

```bash
cd packages/report_engine_sunmi
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Rendering and printing

### PDF

`PdfRenderService` owns document rendering concerns such as page size, margins, text, tables, barcodes/QR codes, pagination, and thermal auto-height.

Physical operations such as cutting paper or opening a cash drawer are printer-capability concerns and do not belong in the PDF renderer.

### Thai PDF

Bundled Thai fonts live in `packages/report_engine/assets/fonts/`. Validation should include real Thai glyph combinations such as:

```text
กุ้ง
น้ำ
สำนักงาน
ยอดรวม 1,250.00 บาท
```

A non-empty PDF alone is not enough to prove Thai glyph correctness.

### ESC/POS

Thai printer firmware and code-page mappings vary. Supported software strategies include:

```text
TIS-620 with explicit printer code table
CP874 with explicit printer code table
Rasterized Thai fallback
```

Do not treat a code-table number verified on one printer as a universal default.

## Printer compatibility policy

Software support and hardware verification are tracked separately. Compatibility evidence distinguishes:

- implemented software
- automated test coverage
- emulator/simulator validation
- physical hardware validation
- needs physical verification

See [docs/PRINTER_COMPATIBILITY.md](docs/PRINTER_COMPATIBILITY.md).

## CI and quality gates

GitHub Actions uses Flutter 3.32.7.

Quality scopes:

```text
report_engine
  → pub get → format → analyze → tests/coverage → publish dry-run

report_engine_sunmi
  → pub get → format → analyze → tests

designer
  → pub get → format → analyze → tests/coverage

report_engine/example
  → pub get → format → analyze → tests → Android APK
```

Designer build gates cover:

```text
Web release
Android APK
Linux release
Windows release
macOS release
iOS simulator
```

The Designer CI job also uploads formatted source/test artifacts when format validation fails, making formatter-only failures reproducible instead of requiring manual guesswork.

A phase is not considered complete until its relevant format, analyze, test, and build gates pass.

## Documentation

- [Production handoff / roadmap](docs/PROJECT_HANDOFF.md)
- [Code walkthrough](docs/CODE_WALKTHROUGH.md)
- [Design system](docs/design/DESIGN_SYSTEM.md)
- [Component spec](docs/design/COMPONENT_SPEC.md)
- [Interaction spec](docs/design/INTERACTION_SPEC.md)
- [Screen mapping](docs/design/SCREEN_MAPPING.md)
- [Designer implementation plan](docs/design/IMPLEMENTATION_PLAN.md)
- [CI design](docs/CI.md)
- [Printer compatibility](docs/PRINTER_COMPATIBILITY.md)

## Continuing development

For a new coding session or agent:

```text
Read docs/PROJECT_HANDOFF.md and docs/design/IMPLEMENTATION_PLAN.md.
Inspect the current repository and open PRs before changing code.
Continue from the first incomplete phase/action.
Preserve report schema, millimeter geometry, persistence, printer boundaries,
and existing keyboard/undo behavior unless a task explicitly changes them.
Run the relevant format/analyze/test/build gates before merging.
```

## Project principles

- Offline-first by default
- One shared template contract
- Physical dimensions stored independently from UI zoom
- Canvas-first responsive Designer UX
- Reusable design-system primitives instead of page-local styling
- Rendering separated from hardware control
- Plugin-specific objects kept out of the public domain model where possible
- Cross-platform behavior must degrade gracefully
- Hardware support must be evidence-based
- Tests validate behavior, not merely absence of exceptions
- Production claims require passing release gates
