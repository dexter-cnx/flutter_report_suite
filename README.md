# Flutter Report Suite

A Flutter monorepo for designing report templates and rendering them offline on Web, desktop, and mobile.

## Architecture

```text
flutter_report_suite/
├── .github/workflows/ci.yml
├── apps/
│   └── designer/
│       └── lib/pages/designer_page.dart
├── packages/
│   └── report_engine/
│       ├── lib/report_engine.dart
│       ├── lib/src/models/report_template.dart
│       ├── lib/src/services/report_value_resolver.dart
│       ├── lib/src/services/pdf_render_service.dart
│       ├── lib/src/services/template_storage_service.dart
│       ├── lib/src/printer/printer_service.dart
│       └── lib/src/printer/esc_pos_printer_service.dart
├── docs/
│   ├── CI.md
│   └── CODE_WALKTHROUGH.md
└── PROMPTS.md
```

The intended flow is:

```text
Designer -> template JSON -> app/local storage -> report_engine -> PDF/system printer/ESC-POS
```

The Designer depends on `report_engine` by path, so PDF preview and exported JSON use the same template contract as runtime printing.

## Quick start

### Report engine

```bash
cd packages/report_engine
flutter pub get
flutter analyze
flutter test
```

### Designer

```bash
cd apps/designer
flutter pub get
flutter analyze
flutter run -d chrome
```

The current repository snapshot contains Designer source/assets but not generated Flutter platform folders. Generate/restore the platform scaffolding before enabling Web, desktop, Android, or iOS build gates.

## Template model

A report consists of:

- `PaperConfig`: type, dimensions, auto-height, margin
- `ReportElement`: type, key, position, size, style, optional table columns
- `ReportTemplate`: id, version, paper, and elements

Dynamic values support nested expressions such as `{{shop.name}}`. Literal `text` elements are not resolved against runtime data.

## Output paths

- `PdfRenderService`: PDF, A4, and thermal PDF rendering
- `FlutterReportPrinter`: preview, share, system printer discovery, direct system printing
- `EscPosPrinterService`: Bluetooth ESC/POS rendering and chunked writes
- `TemplateStorageService`: offline template persistence with Hive

## Designer

The Designer supports:

- Text and dynamic fields
- Lines
- Tables with column mappings
- QR codes and barcodes
- Thermal, A4, and custom PDF paper presets
- Dragging elements on a scaled millimeter canvas
- Property editing for x/y/w/h, font size, bold, and alignment
- PDF preview
- JSON export

## CI

GitHub Actions is configured in `.github/workflows/ci.yml` and pinned to Flutter 3.32.7.

Current quality gates:

```text
report_engine -> flutter pub get -> flutter analyze -> flutter test
designer      -> flutter pub get -> flutter analyze
```

See [docs/CI.md](docs/CI.md) for CI design and planned build/test stages.

## Code walkthrough

See [docs/CODE_WALKTHROUGH.md](docs/CODE_WALKTHROUGH.md) for the end-to-end architecture and code flow, including:

- Designer template authoring
- Template model and JSON contract
- Nested value resolution
- PDF rendering
- system printing
- Bluetooth ESC/POS printing
- Hive template storage
- tests and CI
- a file-level map for future changes

## Notes

Host applications are responsible for platform Bluetooth permission declarations and printer-specific compatibility. The report engine itself remains offline-first and does not require a backend.
