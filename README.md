# Flutter Report Suite

An offline-first Flutter monorepo for designing report templates and rendering them to PDF, system printers, and ESC/POS thermal printers across Web, desktop, and mobile.

> Production v1.0.0 is currently being hardened. See [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md) for the execution roadmap, release gates, and the next implementation steps.

## Goals

Flutter Report Suite is designed around a simple flow:

```text
Designer
   ↓
ReportTemplate JSON
   ↓
Local storage / application data
   ↓
report_engine
   ├── PDF / preview / share
   ├── system printing
   └── ESC/POS thermal printing
```

The project is intentionally **offline-first**. Report generation, template editing, persistence, and printing do not require a backend service.

Primary goals for Production v1.0.0:

- One template contract shared by Designer and runtime rendering
- A4, thermal, and custom-size PDF output
- Thai-capable PDF rendering with bundled fonts
- Thai ESC/POS strategies suitable for real printer hardware
- Local template save/load and JSON import/export
- Responsive Designer for Web, desktop, and mobile
- Unified printer discovery and hardware capability modeling
- Automated analyze/test/build gates in CI
- A reusable `report_engine` package prepared for pub.dev

## Repository structure

```text
flutter_report_suite/
├── .github/
│   └── workflows/
│       └── ci.yml
├── apps/
│   └── designer/
│       ├── assets/templates/
│       └── lib/
├── packages/
│   └── report_engine/
│       ├── assets/templates/
│       ├── lib/
│       │   ├── report_engine.dart
│       │   └── src/
│       │       ├── models/
│       │       ├── printer/
│       │       └── services/
│       └── test/
├── docs/
│   ├── CI.md
│   ├── CODE_WALKTHROUGH.md
│   └── PROJECT_HANDOFF.md
└── README.md
```

## Packages

### `packages/report_engine`

Reusable rendering and printing engine.

Current core services include:

- `ReportTemplate` — shared report/template contract
- `ReportValueResolver` — resolves dynamic expressions such as `{{shop.name}}`
- `PdfRenderService` — PDF rendering for A4, thermal, and custom paper sizes
- `FlutterReportPrinter` — high-level preview/share/system-print facade
- `EscPosPrinterService` — ESC/POS rendering and printer communication
- `TemplateStorageService` — offline Hive template persistence

### `apps/designer`

Visual editor that consumes `report_engine` through a local path dependency, ensuring the Designer and runtime engine use the same template schema.

The current Designer foundation includes:

- Text and dynamic fields
- Lines
- Tables with column mappings
- QR codes and barcodes
- Thermal, A4, and custom paper presets
- Dragging elements on a millimeter-based canvas
- Property editing for position, size, typography, and alignment
- PDF preview
- JSON export foundation

Production Designer V2 work is tracked in [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md), including template gallery, persistent save/load, file import/export, table column editing, rulers, snapping, zoom, and undo/redo.

## Template model

A report is composed from three main concepts:

- `PaperConfig` — paper type, physical dimensions, margins, and auto-height behavior
- `ReportElement` — element type, key, position, dimensions, style, and optional table configuration
- `ReportTemplate` — template identity, schema version, paper configuration, and elements

Runtime values can be addressed through nested expressions:

```text
{{shop.name}}
{{customer.address.city}}
{{items.0.name}}
```

Missing values are expected to degrade safely instead of breaking the complete report.

## Quick start

The Production v1.0.0 reference toolchain is **Flutter 3.32.7**.

Check your Flutter installation:

```bash
flutter --version
```

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

Platform scaffolding is part of the Production v1.0.0 foundation work. If a required platform directory is missing, restore only that platform instead of blindly overwriting the existing project.

Example:

```bash
cd apps/designer
flutter create . --platforms=web
```

The complete platform restoration policy is documented in [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md).

## Rendering and printing

### PDF

`PdfRenderService` is responsible only for document rendering concerns such as:

- Page size
- Margins
- Text
- Tables
- Barcodes / QR codes
- Page breaking
- Thermal auto-height

Physical printer operations such as paper cutting or opening a cash drawer belong to printer adapters/capabilities, not to the PDF rendering layer.

### Thai PDF

Production v1.0.0 requires a redistribution-safe Thai font bundled inside `report_engine` and loaded correctly when the package is consumed by another Flutter application.

Thai rendering must be tested using content such as:

```text
กุ้ง
น้ำ
สำนักงาน
ยอดรวม 1,250.00 บาท
```

A non-empty PDF alone is not considered sufficient proof that Thai glyph rendering is correct.

### ESC/POS

ESC/POS compatibility differs between printer firmware and code pages. Thai support must therefore not assume that one encoding works on every printer.

The Production v1.0.0 roadmap calls for configurable strategies such as:

```text
TIS-620
CP874
Rasterized Thai fallback
```

Physical printer compatibility must be recorded separately from automated test coverage.

## Printer compatibility policy

A printer must not be described as physically tested unless it has actually been verified on hardware.

Compatibility documentation will distinguish between:

- Implemented
- Automated test coverage
- Emulator/simulator verified
- Physically tested
- Needs physical verification

Candidate hardware for Production v1 validation includes:

- XP-80
- XP-58
- Epson TM-T88V
- Sunmi V2

See the production roadmap for the compatibility matrix requirements.

## Offline persistence

`TemplateStorageService` uses Hive for local template persistence.

Production Designer V2 will expose this functionality through a complete template lifecycle:

```text
Create → Edit → Save → Load → Duplicate → Rename → Export / Import
```

Built-in gallery templates remain immutable; editing them should create a working copy.

## CI and quality gates

GitHub Actions is configured under `.github/workflows/ci.yml` and uses Flutter 3.32.7 as the Production v1 reference version.

Current baseline checks include analyzer/test coverage for the existing packages.

The Production v1 CI target expands this to:

```text
report_engine
  → flutter pub get
  → format check
  → flutter analyze
  → flutter test

designer
  → flutter pub get
  → format check
  → flutter analyze
  → flutter test
  → flutter build web

example
  → flutter pub get
  → flutter analyze
  → flutter test
  → flutter build apk
```

A task is not considered complete merely because code was written. Relevant format, analyze, test, and build checks must pass before its roadmap commit is considered complete.

See [docs/CI.md](docs/CI.md) for CI details.

## Production v1.0.0 roadmap

The authoritative execution plan is:

**[docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md)**

It is structured as:

1. Pre-flight repository audit
2. Phase 1 — Foundation
3. Phase 2 — Designer V2
4. Phase 3 — Printer Engine
5. Phase 4 — Hardening
6. Phase 5 — Release
7. Production v1.0.0 release gate

The handoff also defines:

- Sequential task execution
- Conventional commit boundaries
- Definition of Done per task
- Architectural constraints
- Thai PDF acceptance criteria
- Thai ESC/POS fallback strategy
- Hardware verification boundaries
- CI/build gates
- pub.dev preparation
- Firebase Hosting configuration
- Release evidence requirements

## Continuing development with an AI coding agent

When handing the repository to another coding session or agent, use the handoff document as the source of truth.

Recommended instruction:

```text
Read docs/PROJECT_HANDOFF.md in the flutter_report_suite repository.
Inspect the current repository state and continue from the first incomplete Next Action.
Follow the validation, commit, architecture, and release-gate rules in the handoff.
```

The agent should inspect the current repository before changing code. It should not assume the handoff snapshot is newer than the actual implementation.

## Release gate

Production v1.0.0 must not be declared complete until all non-hardware mandatory gates pass, including:

- Clean repository state
- Formatting checks
- Analyzer passes
- Automated tests pass
- Designer Web build passes
- Example Android APK build passes
- PDF regression tests pass
- Thai PDF validation passes
- Template save/load round-trip passes
- JSON import/export round-trip passes
- Undo/redo coverage passes
- pub.dev publish dry-run passes

Hardware-only validations may remain explicitly marked:

```text
NEEDS PHYSICAL VERIFICATION
```

They must never be silently treated as passed.

## Documentation

- [Production handoff / roadmap](docs/PROJECT_HANDOFF.md)
- [Code walkthrough](docs/CODE_WALKTHROUGH.md)
- [CI design](docs/CI.md)

`docs/CODE_WALKTHROUGH.md` explains the current architecture and end-to-end code flow, including template authoring, JSON contracts, nested value resolution, PDF rendering, printing, Hive persistence, tests, and CI.

## Publishing status

`report_engine` is not yet considered ready for pub.dev until the Production v1 release phase is completed.

The release work includes metadata review, README/CHANGELOG/license validation, removal of `publish_to: none` when appropriate, package content inspection, and a successful publish dry-run.

Do not publish the package merely because the package version currently says `1.0.0`.

## Project principles

- Offline-first by default
- One shared template contract
- Physical dimensions stored independently from UI zoom
- Rendering separated from hardware control
- Plugin-specific objects kept out of the public domain model where possible
- Cross-platform behavior must degrade gracefully
- Hardware support must be evidence-based
- Tests must validate behavior, not merely absence of exceptions
- Production claims require passing release gates
