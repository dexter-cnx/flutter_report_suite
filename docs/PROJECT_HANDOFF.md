# Flutter Report Suite — Production v1.0.0 Handoff

Repository: `dexter-cnx/flutter_report_suite`

Reference Flutter toolchain: **Flutter 3.32.7**

Last updated: **2026-08-12**

## Mission

Take the monorepo to a production-ready **v1.0.0** while preserving its offline-first architecture.

Current structure:

```text
flutter_report_suite/
├── apps/designer
├── packages/report_engine
├── packages/report_engine_sunmi
└── docs
```

- `apps/designer` — drag/drop report designer
- `packages/report_engine` — template model, PDF, ESC/POS, printer discovery, Hive/template storage
- `packages/report_engine_sunmi` — optional Android-only Sunmi adapter

## Operating rules

1. Inspect existing code before changing it.
2. Preserve public APIs unless a change is necessary for correctness.
3. Prefer incremental changes over broad rewrites.
4. Keep runtime offline-first; no backend is required.
5. Never weaken tests just to make CI pass.
6. Do not claim physical printer compatibility without physical evidence.
7. Hardware-dependent functionality remains `NEEDS PHYSICAL VERIFICATION` until tested on real hardware.
8. Complete validation, PR review, CI, and merge for one phase before starting the next phase branch.
9. Preserve the existing Designer native build matrix.
10. Keep PDF rendering, ESC/POS rendering, transport, discovery, and physical hardware capabilities as separate responsibilities.

---

# PRE-FLIGHT — Repository Audit

**Status: ✅ COMPLETED — 2026-08-12**

Repository structure, CI, platform folders, `report_engine`, Designer, tests, assets, and existing implementation were audited before roadmap work.

---

# PHASE 1 — FOUNDATION

**Status: ✅ MERGED / COMPLETE**

## 1. Runnable Designer platforms

**Status: ✅ COMPLETED**

Existing Flutter platform projects were preserved and validated for:

- Web
- Android
- iOS
- Linux
- macOS
- Windows

The six-platform CI build matrix remains a required regression gate.

## 2. Production Thai PDF fonts

**Status: ✅ COMPLETED**

Implemented:

- bundled `NotoSansThai-Regular.ttf`
- bundled `NotoSansThai-Bold.ttf`
- package-aware asset loading
- cached PDF font loading
- Thai PDF tests including `กุ้ง`, `น้ำ`, `สำนักงาน`, and mixed Thai/English/numeric content
- font license/integration documentation

## 3. Example application

**Status: ✅ COMPLETED**

`packages/report_engine/example` demonstrates:

- Thermal 80mm preview
- Thermal 58mm preview
- A4 invoice with multi-page rows
- PDF preview/share
- system-printer listing
- ESC/POS quick receipt generation
- Thai PDF
- Thai ESC/POS raster example
- template JSON export/copy

Android example scaffolding is present and the APK debug build has been validated.

## 4. Foundation tests

**Status: ✅ COMPLETED**

Coverage includes:

- nested resolver paths
- list indexes
- interpolation
- null/missing/invalid values
- thermal PDF
- A4 PDF
- multi-page table
- Thai rendering
- structural PDF assertions

---

# PHASE 2 — DESIGNER V2

**Status: ✅ MERGED / COMPLETE — 2026-08-12**

Phase 2 PR was merged to `main` before Phase 3 started.

## 5. Save / Load / Import / Export

**Status: ✅ COMPLETED**

Implemented:

- Create
- Save
- Save As
- Rename
- Load
- Delete
- Duplicate
- Hive persistence
- JSON import/export
- JSON sharing
- malformed/incompatible-template handling
- storage/template ID consistency

## 6. Template Gallery

**Status: ✅ COMPLETED**

Built-in templates:

- 80mm Receipt
- 58mm Receipt
- A4 Invoice
- 4x6 Sticker
- Blank Template

Built-in assets open as editable working copies.

## 7. Table Column Editor

**Status: ✅ COMPLETED**

Supports:

- key
- label
- width
- alignment
- add/remove/edit/reorder
- width validation
- unknown JSON field preservation
- undo/redo

PDF table rendering honors Designer width/alignment metadata.

## 8. Designer precision UX

**Status: ✅ COMPLETED**

Implemented:

- 5mm snap-to-grid
- center guides
- top/left rulers in mm
- zoom 50%–200%
- physical-mm persistence independent of zoom
- Undo / Redo
- grouped drag transactions
- Ctrl/Cmd+Z
- Ctrl/Cmd+Shift+Z
- Delete/Backspace
- arrow-key nudging

---

# PHASE 3 — PRINTER ENGINE

**Status: ✅ MERGED / COMPLETE — 2026-08-12**

Branch:

```text
agent/phase-3-printer-engine
```

Pull request:

```text
PR #7 — Agent/phase 3 printer engine
```

Reviewed head:

```text
97a831c14ab83ff10f93147e7a3942846eb639dd
```

Validation state:

- maintainer local validation: ✅ PASS
- `report_engine` analyze/tests: ✅ PASS
- `report_engine_sunmi` format/analyze/tests: ✅ PASS
- GitHub CI run #49: ✅ PASS
- Designer analyze/tests: ✅ PASS
- Web build: ✅ PASS
- Android build: ✅ PASS
- Linux build: ✅ PASS
- Windows build: ✅ PASS
- macOS build: ✅ PASS
- iOS simulator build: ✅ PASS
- actionable review threads: ✅ RESOLVED

## 9. Thai ESC/POS

**Status: ✅ COMPLETED — SOFTWARE VALIDATION**

Implemented:

```dart
enum ThaiEncoding {
  tis620,
  cp874,
  rasterImage,
}
```

Public configuration uses only valid construction paths:

```dart
EscPosEncodingConfig.tis620(codeTable: ...)
EscPosEncodingConfig.cp874(codeTable: ...)
EscPosEncodingConfig.raster()
```

There is no public general-purpose constructor that can create a TIS-620/CP874 configuration without a code table. This keeps the invariant valid in release builds as well as debug builds.

Implemented:

- TIS-620 byte encoding
- CP874 byte encoding/extensions
- printer-specific code table selection
- rasterized Thai fallback
- bundled Noto Sans Thai raster rendering
- encoding isolated from transport
- `กุ้ง`
- `น้ำ`
- `ยอดรวม`
- mixed Thai/English
- Thai numerals

Quick-receipt item layout preserves the original **8/2/2** semantic columns:

- item name: width 8, left aligned
- quantity: width 2, centered
- price: width 2, right aligned

Legacy output uses ESC/POS row layout. Code-page/raster paths provide equivalent fixed/measured column layout.

**Physical printer compatibility remains pending.**

## 10. Unified Printer Discovery

**Status: ✅ COMPLETED**

Core domain model:

```dart
enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}
```

`UnifiedPrinter` does not expose raw plugin objects.

`PrinterDiscoveryService.discoverAll()` provides:

- source composition
- deterministic IDs where available
- deduplication
- deterministic ordering
- exception isolation per source
- extensible additional discovery sources

Current built-in sources:

- system printers via `printing`
- Bluetooth LE via `flutter_blue_plus`

Important limitation:

> `flutter_blue_plus` is BLE-only. Bluetooth Classic thermal printers require a separate future adapter/plugin.

## 11. Sunmi support

**Status: ✅ COMPLETED — SOFTWARE VALIDATION**

Sunmi is isolated in:

```text
packages/report_engine_sunmi
```

Reason: `sunmi_printer_plus` is Android-specific, so direct inclusion in core would contaminate Web/Desktop/iOS dependency boundaries.

Implemented:

- ESC/POS transport through Sunmi embedded printer service
- embedded printer discovery
- printer service rebind support
- optional cutter capability
- optional cash-drawer capability

### Safe capability model

`SunmiPrinterAdapter` is **print-only by default**.

The host must supply a verified device profile before optional hardware operations are exposed:

```dart
const SunmiHardwareProfile(
  supportsCutter: true,
  supportsCashDrawer: false,
)
```

The adapter factory returns capability-bearing implementations only when the supplied hardware profile confirms support. Therefore a model without a cutter does not pass `is CutterCapability`, and a model without a cash-drawer port does not pass `is CashDrawerCapability`.

Do not infer Sunmi model capabilities without hardware/device inventory evidence.

**Physical Sunmi verification remains pending.**

See:

```text
docs/PHASE3_SUNMI_ADAPTER_AUDIT.md
```

## 12. Hardware capabilities

**Status: ✅ COMPLETED**

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

Rules now enforced:

- `PdfRenderService` has no hardware commands
- `EscPosRenderer` has no implicit cut command
- `EscPosPrinterService` does not synthesize cutter bytes
- cut is invoked only through explicit `CutterCapability`
- unsupported cut requests fail before transport sends the print payload
- capability tests verify `send -> cut` ordering
- adapters implement only capabilities confirmed for the target hardware profile

Validation evidence:

```text
docs/PHASE3_TASK9_11_VALIDATION.md
```

The file name is historical; its content records Tasks 9–12.

---

# PHASE 4 — HARDENING

**Status: ✅ MERGED / COMPLETE — 2026-08-12**

> Handoff status was prepared on the Phase 4 branch immediately before merging PR #8. At the time of this documentation commit, implementation and validation are complete and the only remaining Phase 4 action is the GitHub merge itself.

Branch:

```text
agent/phase-4-hardening
```

Pull request:

```text
PR #8 — Phase 4 hardening: CI, rendering regressions, and printer docs
```

Validated head before merge:

```text
eab0b86b7f720f5e53afbcb6eb058a982ee78e3e
```

GitHub Actions validation:

```text
CI run #65 / run id 31588118361 — ✅ SUCCESS
```

All nine jobs passed:

- `report_engine` format + analyze + tests: ✅ PASS
- `report_engine_sunmi` format + analyze + tests: ✅ PASS
- Designer format + analyze + tests: ✅ PASS
- `report_engine/example` format + analyze + tests + Android APK: ✅ PASS
- Designer Web release build: ✅ PASS
- Designer Android APK build: ✅ PASS
- Designer Linux release build: ✅ PASS
- Designer Windows release build: ✅ PASS
- Designer macOS release + iOS simulator build: ✅ PASS

## 13. CI

**Status: ✅ COMPLETED**

`.github/workflows/ci.yml` now uses Flutter **3.32.7** and directly validates all required package/app scopes.

### report_engine

- pub get
- format check
- analyze
- tests + coverage

### report_engine_sunmi

Dedicated companion-package quality job:

- pub get
- format check
- analyze
- tests

### designer

- pub get
- format check
- analyze
- tests + coverage

### build matrix

Retained and validated:

- Web release
- Android APK
- Linux release
- Windows release
- macOS release
- iOS simulator

### example

Validated:

- pub get
- format check
- analyze
- tests
- Android debug APK build

The Phase 4 CI gate also exposed formatting debt from earlier work; those files were normalized rather than weakening or narrowing the format checks.

## 14. Rendering regression tests

**Status: ✅ COMPLETED**

Deterministic/stable regression coverage now protects:

- Thermal 80mm
- Thermal 58mm
- A4 page geometry
- A4 invoice with 25+ rows
- multi-page pagination
- Thai A4 invoice

Regression assertions deliberately prefer stable PDF properties over raw PDF byte equality:

- `%PDF-` header / valid PDF structure
- `%%EOF`
- page-object count
- `/MediaBox` dimensions
- pagination behavior
- minimum output-size sanity for Thai font embedding

This avoids false failures from timestamps, metadata, and nondeterministic PDF object details while still detecting rendering regressions.

## 15. Documentation

**Status: ✅ COMPLETED**

Created/updated:

```text
docs/PRINTER_COMPATIBILITY.md
docs/CODE_WALKTHROUGH.md
docs/PHASE4_HARDENING_VALIDATION.md
docs/PROJECT_HANDOFF.md
```

Printer compatibility documentation separates:

- Implemented software
- Automated test coverage
- Emulator/simulator verification
- Physical hardware verification

Candidate hardware documented:

- XP-80
- XP-58
- Epson TM-T88V
- Sunmi V2

None of these models are marked physically verified without real hardware evidence.

Hardware-dependent compatibility remains:

```text
NEEDS PHYSICAL VERIFICATION
```

---

# PHASE 5 — RELEASE

**Status: ✅ MERGED / COMPLETE — 2026-08-12**

Branch:

```text
agent/phase-5-release
```

Pull request:

```text
PR #9 — Phase 5 release readiness and GitHub Pages
```

Merge commit:

```text
be3378a69794732e12935ea594aa09a4a9b9e2e4
```

Validation:

- PR CI run #68: ✅ SUCCESS
- post-merge CI run #69 / run id `31591471768`: ✅ SUCCESS
- GitHub Pages workflow run #1: ✅ SUCCESS
- live Pages smoke test: ✅ PASS

## 16. Prepare `report_engine` for pub.dev

**Status: ✅ COMPLETED**

Completed:

- description / repository / issue tracker metadata
- pub.dev topics
- package-level license
- package README
- CHANGELOG
- publication artifact review
- `flutter pub publish --dry-run` as a CI gate

Publication strategy:

- `report_engine` — publish-ready `1.0.0` candidate
- `report_engine_sunmi` — remains unpublished for this release cycle

Dry-run result:

```text
report_engine • format + analyze + test + publish dry-run — ✅ PASS
```

## 17. Designer Web deployment

**Status: ✅ COMPLETED**

GitHub Pages replaced the earlier Firebase Hosting proposal because Designer is a static, backend-free Flutter Web application.

Deployment target:

```text
https://dexter-cnx.github.io/flutter_report_suite/
```

Implemented and validated:

- dedicated `.github/workflows/pages.yml`
- GitHub Pages publishing source: GitHub Actions
- build base href `/flutter_report_suite/`
- Web metadata updates
- workflow build: ✅ PASS
- workflow deploy: ✅ PASS
- live site smoke test: ✅ PASS

No SPA rewrite workaround is required by the current Designer navigation because the app currently uses `MaterialApp(home: ...)` rather than path-based deep-link routing.

---

# RELEASE GATE — v1.0.0

Before declaring v1.0.0 production-ready:

- [ ] repository clean
- [x] format checks pass
- [x] `report_engine` analyzer/tests pass
- [x] `report_engine_sunmi` analyzer/tests pass
- [x] Designer analyzer/tests pass
- [x] Designer Web build passes
- [x] Designer Android APK build passes
- [x] Designer Linux build passes
- [x] Designer Windows build passes
- [x] Designer macOS build passes
- [x] Designer iOS simulator build passes
- [x] Example Android APK builds
- [x] publish dry-run passes
- [x] GitHub Pages deployment passes
- [x] GitHub Pages live smoke passes
- [x] bundled Thai PDF rendering implemented and tested
- [x] ESC/POS Thai encoding tests pass
- [x] save/load round trip passes
- [x] import/export workflow implemented and validated
- [x] undo/redo tests pass
- [x] A4 multi-page software output coverage exists
- [x] printer compatibility documentation complete
- [ ] physical printer evidence recorded where available

Hardware-dependent items remain:

```text
NEEDS PHYSICAL VERIFICATION
```

until tested on actual devices.

---

# Current next action

1. Create and push the `v1.0.0` tag.
2. Create the GitHub Release for `v1.0.0`.
3. Publish `packages/report_engine` to pub.dev.
4. Keep `report_engine_sunmi` unpublished until its own release decision and dependency strategy are approved.
5. Record physical printer validation evidence when hardware becomes available.
6. Treat Designer visual/UX modernization as post-v1 work so it does not block the validated release baseline.
