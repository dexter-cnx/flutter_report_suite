# Flutter Report Suite

A Flutter monorepo for designing report templates and rendering them offline on Web, desktop, and mobile.

## Architecture

```text
flutter_report_suite/
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
flutter test
```

### Designer

```bash
cd apps/designer
flutter pub get
flutter run -d chrome
```

Use another Flutter device target for Windows, macOS, Linux, Android, or iOS.

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

## Notes

Host applications are responsible for platform Bluetooth permission declarations and printer-specific compatibility. The report engine itself remains offline-first and does not require a backend.
