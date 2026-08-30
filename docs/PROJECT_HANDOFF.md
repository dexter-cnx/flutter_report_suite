# Flutter Report Suite — Production v1.0.0 Handoff

Repository: `dexter-cnx/flutter_report_suite`

Reference Flutter toolchain: **Flutter 3.32.7**

Last updated: **2026-08-31**

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
- `report_engine_sunmi` format/analyze/tests: ✅ PASS
- Designer format/analyze/tests: ✅ PASS
- `report_engine/example` format/analyze/tests + Android APK: ✅ PASS
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

# Designer Stitch UI modernization

**Status: ✅ P1–P9 COMPLETE — 2026-08-13**

The normalized visual migration plan is tracked in:

```text
docs/design/IMPLEMENTATION_PLAN.md
```

Completed merge sequence:

- P1 + P2 tokens/theme/shared controls — PR #12
- P3 + P4 shell/canvas primitives — PR #13
- P3 + P4 live Designer migration — PR #14
- P5 Inspector — PR #15
- P6 Left panel/Layers/Data shell — PR #16
- P7 Template Gallery — PR #17
- P8 Table UX expansion — PR #18, merge `18331aa9d667771ee4878b5e0c34db327bc9f774`
- P9A PDF/system print preview — PR #19, merge `99e0785c3a4032400c8c519102b5e2c0de5baa32`
- P9B ESC/POS preview mode — PR #20, merge `9cfd4a3b31f69163c37aea13be4087cfa9e74d15`

P9B final validated head:

```text
4cd8973b1cc66b32a3173519c877a3c50333267b
```

Final P9 validation:

```text
CI run #147 / run id 31685965055 — ✅ SUCCESS
```

All nine jobs passed.

P9 delivered:

- unified PDF/System Print preview workspace
- PDF ↔ ESC/POS mode switching
- actual PDF bytes from existing report engine functionality
- actual ESC/POS bytes from `EscPosRenderer.renderTemplate()`
- `ReportTemplate.fromJson(...)` integration with current Designer document/data
- ESC/POS byte count and bounded hex preview
- System Print only in PDF mode
- ESC/POS mode only when a real rendered payload exists
- thermal-only Designer ESC/POS generation; A4/PDF are not silently mapped to thermal
- no implicit transport send
- no invented printer connected/status state
- no invented cutter/cash-drawer controls

Architecture guardrails remain:

- `EscPosRenderer` is transport-agnostic.
- Actual sending requires an explicit `EscPosTransport`.
- Cutter/cash-drawer actions require actual `CutterCapability` / `CashDrawerCapability` implementations.
- Hardware-dependent compatibility still requires physical evidence.

---

# P10 — Printing Architecture & Printer Profiles

**Status: 🟡 PLANNED — added 2026-08-30**

This roadmap is informed by useful concepts seen in `nitro_printing`, but Flutter Report Suite should preserve its own responsibility boundary: **report/template/layout/rendering is the core product; printer transport and platform integration are separate layers.** Do not replace the Dart report engine with a native/FFI printing core merely to mirror another package.

## P10.1 — Formalize renderer / transport separation — P0

Preserve and make explicit the pipeline:

```text
ReportTemplate
    ↓
ReportDocument / resolved data
    ↓
Renderer
    ├── PDF
    ├── ESC/POS
    ├── Raster/Image
    └── ZPL [future]
    ↓
ReportArtifact
    ↓
Printer transport / system print / file export
```

Requirements:

- rendering must never imply transport I/O
- report templates must not contain plugin/native printer objects
- transport packages/adapters must consume rendered artifacts rather than own document layout
- printer discovery must remain independent from report rendering
- hardware commands remain capability-gated

Target artifact domain:

```dart
sealed class ReportArtifact {}

final class PdfArtifact extends ReportArtifact {
  final Uint8List bytes;
}

final class EscPosArtifact extends ReportArtifact {
  final Uint8List bytes;
}

final class ImageArtifact extends ReportArtifact {
  final Uint8List bytes;
}
```

A future `ZplArtifact` may be added without changing template/data contracts.

## P10.2 — PrinterProfile — P0

Introduce a neutral printer profile model for verified printer-specific behavior rather than scattering model checks and encoding assumptions through renderers/transports.

Candidate fields:

```text
id
vendor
model
connection hints
default paper width
DPI / dots per line
supported code pages
Thai encoding strategy
raster strategy
cut support
cash-drawer support
```

Example intent (fictional profile; values are illustrative only and do not claim compatibility with real hardware):

```dart
PrinterProfile(
  id: 'example-thermal-80',
  vendor: 'Example',
  model: 'Demo-80',
  type: PrinterType.escPos,
  paperWidthMm: 80,
  dotsPerLine: 576,
  thaiEncoding: ThaiEncoding.rasterImage,
  supportsCut: false,
)
```

Rules:

- a profile is configuration/evidence, not a raw plugin object
- do not claim model capabilities without evidence
- physical-only claims remain `NEEDS PHYSICAL VERIFICATION`
- Thai encoding/code-table choices should be profile-driven where printer behavior differs
- examples must use fictional/generic profiles unless the values are backed by repository evidence

This is the primary follow-up for real Thai thermal-printer compatibility.

## P10.3 — PrinterCapabilities — P0

Add a capability model that can represent both office/system printers and thermal printers.

Candidate capability dimensions:

```text
PDF/system print
ESC/POS
raster
paper sizes / paper widths
DPI / dots per line
color
copies
orientation
duplex
cut
cash drawer
supported code pages
input tray / media type where available
```

The Designer and print orchestration layer must consume capabilities instead of inferring support from printer names.

For thermal printers, examples include 58mm/80mm paper support and raster/code-page constraints. For system printers, capabilities may include A4/Letter, duplex, color, copies, trays, and media types when the platform exposes them.

## P10.4 — Unified print settings — P1

Define cross-renderer settings without leaking transport-specific options into the generic model.

Example generic settings:

```text
paper
orientation
copies
page range
fit mode
margins
```

Thermal/ESC-POS-specific settings remain separate, for example:

```text
paper width
encoding/code table
cut after print
cash drawer action
raster density
```

Do not create a single oversized settings object containing invalid combinations for every backend.

## P10.5 — Typed PrintResult / PrintFailure — P1

Replace stringly-typed failure handling in new printing APIs with explicit domain failures.

Candidate failures:

```dart
sealed class PrintFailure {}

final class PrinterOffline extends PrintFailure {}
final class ConnectionTimeout extends PrintFailure {}
final class UnsupportedEncoding extends PrintFailure {}
final class PaperWidthMismatch extends PrintFailure {}
final class RenderFailure extends PrintFailure {}
final class TransportFailure extends PrintFailure {}
```

Requirements:

- preserve original exception/cause information for diagnostics
- distinguish rendering failures from transport failures
- distinguish unsupported capability/configuration from runtime connection failure
- make failures useful to both package consumers and Designer UX

## P10.6 — Print job lifecycle — P1

Introduce a small print-job domain rather than a full operating-system spooler.

Suggested states:

```dart
enum ReportPrintState {
  queued,
  rendering,
  connecting,
  sending,
  completed,
  failed,
  cancelled,
}
```

Expose job events/progress where the underlying transport can provide meaningful progress.

Do not invent pause/resume/progress semantics for transports that cannot support them reliably.

Designer target UX may show real lifecycle stages such as rendering, connecting, sending, completed, and failed.

## P10.7 — Test printer connection — P1

Add a transport-level connection/health check API where technically meaningful.

Target behavior:

- TCP/network printer: socket/transport reachability
- embedded printer: service availability
- system printer: platform availability where exposed
- BLE/USB: adapter/device availability where exposed

Return typed results; do not treat a discovery result as proof that printing will succeed.

## P10.8 — ESC/POS live visual preview — P1

Extend P9B beyond byte/hex inspection to a human-readable thermal-paper preview generated from the same layout/rendering semantics used for actual ESC/POS output.

Designer preview targets:

```text
A4 / PDF
80mm thermal
58mm thermal
```

Requirements:

- preview must reflect printer profile width/dots when supplied
- Thai raster/code-page strategy must be represented as faithfully as practical
- preview must not claim physical output fidelity without printer evidence
- continue exposing raw byte/hex inspection for diagnostics

## P10.9 — Printer discovery expansion — P2

Keep the existing `PrinterDiscoveryService` abstraction and expand it via source adapters rather than rewriting discovery around one plugin.

Future sources may include:

```text
mDNS / Bonjour / IPP
manual TCP 9100
USB
Bluetooth Classic
BLE
system printers
embedded printers
```

Important: Bluetooth Classic support is a separate requirement from the existing BLE discovery implementation.

## P10.10 — Batch generation / batch printing — P2

Support repeated document generation and printing without coupling the template engine to a spooler.

Use cases:

- invoice batch
- receipt batch
- label batch
- CSV/JSON row-driven generation

Target workflow:

```text
Data source
  ↓
rows
  ↓
Template + row data
  ↓
N ReportArtifacts
  ↓
export batch or print queue
```

Batch APIs must provide per-item results so one failed print does not erase successful item evidence.

## P10.11 — Designer Printer Manager / Print Settings — P2

After the domain APIs stabilize, add Designer UX for:

- discovered/saved printers
- printer profiles
- real capabilities
- connection test
- paper/profile selection
- print settings
- job state/errors

Do not show invented online/connected/cutter/cash-drawer status. UI state must come from real capability/discovery/health-check evidence.

## P10.12 — IPP and ZPL — P3

Reserve architecture for two future outputs/integrations:

### IPP

Useful for standards-based network/system printing and richer printer capabilities where platforms/devices expose them.

### ZPL

Add as a future renderer/artifact for label-printer workflows such as:

- shipping labels
- warehouse labels
- inventory/barcode labels
- logistics tags

ZPL is not required for v1.0.0. The immediate requirement is to ensure current template/rendering architecture does not prevent a future `ZplRenderer`.

## Proposed package direction

Do not perform a package split only for aesthetics. When implementation pressure justifies it, the target responsibility model is:

```text
flutter_report_suite
│
├── report_engine
│   ├── document
│   ├── layout
│   ├── template
│   └── data binding
│
├── report_renderers [logical boundary; package split optional]
│   ├── pdf
│   ├── escpos
│   ├── raster
│   └── zpl [future]
│
├── report_printing [future package if dependency boundaries justify it]
│   ├── printer
│   ├── capabilities
│   ├── profiles
│   ├── discovery
│   ├── print_job
│   └── transports
│       ├── tcp
│       ├── system
│       ├── bluetooth
│       └── usb
│
└── designer
    ├── template editor
    ├── print preview
    ├── printer manager
    └── print settings
```

Do not move the report/layout core to FFI/native merely for theoretical call overhead. Current likely bottlenecks remain layout, font shaping, PDF generation, rasterization, encoding conversion, and physical/network printer latency. Native/FFI work requires benchmark evidence before becoming a roadmap item.

## P10 implementation order

1. **P0:** `ReportArtifact` + formal renderer/transport boundaries
2. **P0:** `PrinterProfile`
3. **P0:** `PrinterCapabilities`
4. **P1:** unified print settings
5. **P1:** typed result/failure domain
6. **P1:** print job lifecycle
7. **P1:** connection test API
8. **P1:** ESC/POS visual preview
9. **P2:** discovery expansion
10. **P2:** batch generation/printing
11. **P2:** Designer Printer Manager
12. **P3:** IPP
13. **P3:** ZPL

Every P10 PR must preserve existing PDF/ESC-POS behavior and the six-platform Designer CI matrix unless the PR explicitly changes a supported-platform contract.

---

# Current next action

The Designer Stitch modernization plan ends at **P9**. **P10 is now defined as the separate post-release printing architecture roadmap**, while the **v1.0.0 release actions remain the current project priority until completion evidence is recorded**. See `docs/design/IMPLEMENTATION_PLAN.md` for the completed Stitch sequence and this handoff for P10.

1. Create and push the `v1.0.0` tag.
2. Create the GitHub Release for `v1.0.0`.
3. Publish `packages/report_engine` to pub.dev.
4. Keep `report_engine_sunmi` unpublished until its own release decision and dependency strategy are approved.
5. Record physical printer validation evidence when hardware becomes available.
6. After the v1 release actions are complete, start P10 from its P0 architecture items: `ReportArtifact`, renderer/transport boundaries, `PrinterProfile`, and `PrinterCapabilities`.

Do not mark tag/release/pub.dev publication complete without concrete repository/pub.dev evidence.
