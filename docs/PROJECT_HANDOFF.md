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

**Status: ✅ IMPLEMENTATION + LOCAL VALIDATION + PR REVIEW + CI COMPLETE — 2026-08-12**

Branch:

```text
agent/phase-3-printer-engine
```

Pull request:

```text
PR #7 — Agent/phase 3 printer engine
```

Current reviewed head:

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
- PR mergeable: ✅ YES

**Phase boundary:** merge PR #7 into `main` before creating or starting Phase 4 work.

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

**Status: ⏳ NEXT — DO NOT START UNTIL PR #7 IS MERGED**

## 13. CI

Strengthen `.github/workflows/ci.yml` using Flutter **3.32.7** without reducing existing platform coverage.

Required gates:

### report_engine

- pub get
- format check
- analyze
- tests

### report_engine_sunmi

Add an explicit companion-package quality job:

- pub get
- format check
- analyze
- tests

This is important because Phase 3 validation showed that the existing CI did not directly run the Sunmi package gate.

### designer

- pub get
- format check
- analyze
- tests

### build matrix

Retain:

- Web release
- Android APK
- Linux release
- Windows release
- macOS release
- iOS simulator

### example

Add/retain:

- pub get
- analyze
- tests
- Android APK build

Commit target:

```text
ci: validate engine designer and example
```

## 14. Rendering regression tests

Add deterministic/stable regression coverage for:

- Thermal 80mm
- Thermal 58mm
- A4 invoice with 25+ rows
- Thai invoice

Prefer stable properties over raw PDF byte equality when metadata/object ordering is nondeterministic:

- valid PDF structure
- page count
- page dimensions
- expected render/content operations
- rendered golden where feasible

## 15. Documentation

Create/update:

```text
docs/PRINTER_COMPATIBILITY.md
docs/CODE_WALKTHROUGH.md
```

Printer compatibility must separate:

- Implemented
- Automated test coverage
- Emulator/simulator verified
- Physically tested

Candidate hardware:

- XP-80
- XP-58
- Epson TM-T88V
- Sunmi V2

Never mark a model physically tested without real hardware evidence.

---

# PHASE 5 — RELEASE

## 16. Prepare `report_engine` for pub.dev

Review publication metadata and artifacts:

- description
- repository
- homepage/issue tracker where appropriate
- topics
- license
- README
- CHANGELOG
- publish dry-run
- exclusions

`publish_to: none` must remain until the package is actually ready for publication.

The companion `report_engine_sunmi` publication strategy must also be decided because it currently depends on core through a monorepo path dependency.

## 17. Designer Web deployment

Add Firebase Hosting configuration for `apps/designer` while keeping application runtime backend-free.

Verify:

- web base path
- SPA fallback
- caching strategy
- deployment instructions
- successful Web build

Do not claim deployment success without valid credentials and an actual deployment.

---

# RELEASE GATE — v1.0.0

Before declaring v1.0.0 production-ready:

- [ ] repository clean
- [ ] format checks pass
- [ ] `report_engine` analyzer/tests pass
- [ ] `report_engine_sunmi` analyzer/tests pass
- [ ] Designer analyzer/tests pass
- [ ] Designer Web build passes
- [ ] Designer Android APK build passes
- [ ] Designer Linux build passes
- [ ] Designer Windows build passes
- [ ] Designer macOS build passes
- [ ] Designer iOS simulator build passes
- [ ] Example Android APK builds
- [ ] publish dry-run passes
- [x] bundled Thai PDF rendering implemented and tested
- [x] ESC/POS Thai encoding tests pass
- [x] save/load round trip passes
- [x] import/export workflow implemented and validated
- [x] undo/redo tests pass
- [x] A4 multi-page software output coverage exists
- [ ] printer compatibility documentation complete
- [ ] physical printer evidence recorded where available

Hardware-dependent items remain:

```text
NEEDS PHYSICAL VERIFICATION
```

until tested on actual devices.

---

# Current next action

1. Merge **PR #7** into `main` after final maintainer approval.
2. Pull/update `main`.
3. Create a new Phase 4 branch from updated `main`.
4. Start **Task 13 — CI hardening**, including a dedicated `report_engine_sunmi` quality gate.
5. Do not carry Phase 4 changes on `agent/phase-3-printer-engine`.
