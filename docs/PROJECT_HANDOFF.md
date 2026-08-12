# Flutter Report Suite — Production v1.0.0 Handoff

Repository: `dexter-cnx/flutter_report_suite`

Reference Flutter toolchain: **Flutter 3.32.7**

## Mission

Take the current monorepo to a production-ready **v1.0.0** while preserving its offline-first architecture.

Current structure:

- `packages/report_engine` — PDF, thermal, ESC/POS, Hive/template storage
- `apps/designer` — drag/drop report designer
- existing CI — analyze/test coverage plus compile-level validation for Designer on Android, iOS simulator, Web, Linux, macOS, and Windows

Known gaps:

- verify and preserve the existing six-platform Designer scaffolding/build matrix
- production Thai PDF fonts
- real Thai ESC/POS handling
- Designer save/load lifecycle
- table editor
- stronger printer abstraction
- example-app platform scaffolding for APK validation
- release hardening and publish/deploy preparation

## Operating Rules

Before changing code:

1. Inspect the current repository and existing implementation.
2. Do not blindly recreate or overwrite existing files.
3. Preserve public APIs unless change is necessary.
4. Prefer incremental changes over broad rewrites.
5. Keep runtime fully offline-first; no backend is required.
6. Do not claim physical printer compatibility without physical evidence.
7. Commit after each roadmap task only when its validation passes.
8. If a roadmap instruction conflicts with the existing architecture, implement the architectural equivalent and document the deviation.
9. Never weaken tests simply to make CI pass.
10. Reuse dependencies already present in the repo instead of adding duplicates.
11. Treat the existing CI platform build jobs as regression gates; do not remove native Designer build coverage merely to satisfy a narrower roadmap checklist.

---

# PRE-FLIGHT — Repository Audit

**Status: ✅ COMPLETED — 2026-08-12**

The baseline repository audit is complete. Repository structure, branch/working state, root configuration, `packages/report_engine`, `apps/designer`, existing tests, `.github/workflows`, and Designer platform folders were reviewed before Phase 1 work. Existing compatibility issues found during the baseline were handled separately from roadmap regressions.

Completed audit scope:

- inspect repository tree
- check current branch and working tree
- inspect root configuration
- inspect `packages/report_engine`
- inspect `apps/designer`
- inspect existing tests
- inspect `.github/workflows`
- inspect platform folders

Baseline commands were run where applicable:

```bash
flutter pub get
flutter analyze
flutter test
```

Existing failures were recorded separately from regressions introduced by roadmap work.

PRE-FLIGHT is complete; Phase 1 work may proceed.

---

# PHASE 1 — FOUNDATION

## 1. Verify and preserve runnable Designer platforms

The current repository already contains Flutter 3.32.7 platform scaffolding for `apps/designer` on:

- Web
- Android
- iOS
- Linux
- macOS
- Windows

Treat this task as **verification/migration of the existing six-platform setup**, not platform restoration.

Requirements:

- inspect each existing platform project before changing it
- preserve application identifiers, signing/configuration placeholders, generated-project customizations, and plugin integration
- use `flutter create` only if a platform folder is genuinely missing or structurally broken
- if regeneration is required, diff generated output before accepting it and avoid overwriting app-specific configuration
- keep all six platforms represented in CI build/smoke coverage

Validate at minimum:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Also preserve or run the platform-specific compile gates already represented in CI:

- Android APK
- Linux desktop
- Windows desktop
- macOS desktop
- iOS simulator

Commit:

```text
chore(designer): verify Flutter platform projects
```

## 2. Production Thai PDF fonts

Bundle an open-license Thai font suitable for redistribution.

Preferred:

- Noto Sans Thai Regular
- Noto Sans Thai Bold

Store under:

```text
packages/report_engine/assets/fonts/
```

Requirements:

- register fonts/assets correctly in `packages/report_engine/pubspec.yaml`
- update `PdfRenderService` to use the bundled Thai font
- resolve Flutter package asset paths correctly when consumed from another app
- do not assume an application-relative asset path
- cache loaded font data during rendering where practical
- use fallback fonts only when bundled fonts cannot be loaded

Test strings:

- `กุ้ง`
- `น้ำ`
- `สำนักงาน`
- mixed Thai / English / numeric content

Validation must establish more than `bytes.isNotEmpty`.

Create a Thai PDF fixture suitable for visual inspection.

Commit:

```text
feat(pdf): bundle Thai fonts and support Thai rendering
```

## 3. Example application

Create or complete:

```text
packages/report_engine/example/
```

The example must demonstrate the public API of `report_engine`.

Before making Android APK build a CI/release gate, ensure the example has valid Flutter platform scaffolding. At minimum, provision and validate:

```text
packages/report_engine/example/android/
```

Use `flutter create` from the example directory only for missing example platform scaffolding and preserve the existing `lib/`, assets, and package configuration.

Required examples:

- Thermal 80mm preview
- Thermal 58mm preview
- A4 invoice with at least 25 rows and page breaking
- PDF preview/share
- printer discovery
- ESC/POS quick receipt
- Thai PDF
- Thai ESC/POS when supported
- template import/export where applicable

Printer actions must degrade gracefully on unsupported platforms.

Prefer a public facade such as:

```dart
final printer = FlutterReportPrinter();

final pdf = await printer.generatePdf(
  templateJson: template,
  data: data,
);
```

If the current API differs, preserve compatibility or add a documented facade.

Validation must include a successful example Android compile before Task 13 relies on it:

```bash
cd packages/report_engine/example
flutter pub get
flutter analyze
flutter build apk --debug
```

Commit:

```text
feat(example): add report engine showcase app
```

## 4. Foundation tests

Expand `ReportValueResolver` coverage:

- `{{shop.name}}`
- `{{items.0.name}}`
- deeper nested paths
- missing key returns empty
- null values
- invalid array indexes
- numeric values
- boolean values

Expand `PdfRenderService` tests:

- Thermal 80mm
- Thermal 58mm
- A4
- multi-page table
- Thai text
- empty data
- missing optional values

Verify generated output structurally where practical, not only byte count.

Commit:

```text
test(engine): expand resolver and PDF coverage
```

---

# PHASE 2 — DESIGNER V2

## 5. Save / Load / Import / Export

Integrate the existing `TemplateStorageService` with Designer.

Required operations:

- Create
- Save
- Save As
- Rename
- Load
- Delete
- Duplicate

JSON workflow:

- Import from file
- Export to file
- Share JSON using `share_plus`

`file_picker` already exists in the Designer dependency set; reuse it rather than adding a duplicate dependency.

Requirements:

- malformed JSON must fail gracefully
- incompatible templates must report a useful error
- exported templates should include a schema/version field if one does not already exist

Commit:

```text
feat(designer): add persistent template lifecycle
```

## 6. Template Gallery

Add a Designer home/gallery before entering the canvas.

Built-in templates:

- 80mm Receipt
- 58mm Receipt
- A4 Invoice
- 4x6 Sticker

Load templates from packaged assets.

Built-in templates are immutable; editing must create a working copy.

Responsive layouts must support:

- mobile
- tablet
- desktop/web

Commit:

```text
feat(designer): add template gallery
```

## 7. Table Column Editor

When a table element is selected, allow editing columns containing:

```text
key
label
width
alignment
```

Required operations:

- add
- remove
- edit
- reorder

Requirements:

- prevent invalid/negative widths
- normalize width allocation where appropriate
- preserve compatible unknown JSON fields
- support undo/redo

Commit:

```text
feat(designer): add table column editor
```

## 8. Designer precision UX

Implement:

- 5mm snap-to-grid
- center guides
- ruler in mm on top
- ruler in mm on left
- zoom 50%–200%
- Undo
- Redo

Coordinate-system rule:

> Persist document geometry in physical document units. Zoom affects rendering only and must not mutate saved element dimensions.

Undo/redo must cover:

- add
- delete
- move
- resize
- property changes
- table column edits

Desktop/Web keyboard support:

- Ctrl/Cmd+Z
- Ctrl/Cmd+Shift+Z
- Delete/Backspace
- optional arrow-key nudging

Commit:

```text
feat(designer): add precision editing tools
```

---

# PHASE 3 — PRINTER ENGINE

## 9. Thai ESC/POS

Do not assume all ESC/POS printers use the same Thai code page.

Introduce a configurable encoding strategy, for example:

```dart
enum ThaiEncoding {
  tis620,
  cp874,
  rasterImage,
}
```

Requirements:

- support code-page based Thai encoding where compatible
- support rasterized Thai text fallback for printers with unreliable Thai code pages
- select strategy from printer configuration/capabilities
- keep encoding logic isolated from transport logic

Test fixtures:

- `กุ้ง`
- `น้ำ`
- `ยอดรวม`
- mixed Thai/English
- Thai numerals where applicable

Add unit tests for encoding output.

Physical printer validation remains required before final compatibility claims.

Commit:

```text
feat(escpos): add configurable Thai printing
```

## 10. Unified Printer Discovery

Create a unified model similar to:

```dart
enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}

class UnifiedPrinter {
  final String id;
  final String name;
  final PrinterConnectionType type;
}
```

Avoid exposing plugin-specific raw objects in the public domain model unless required.

`discoverAll()` should combine available mechanisms while:

- deduplicating printers
- handling unsupported platforms
- isolating plugin exceptions
- providing deterministic IDs where possible

Commit:

```text
feat(printer): add unified discovery
```

## 11. Sunmi support

Treat Sunmi as a platform-specific printer adapter.

Before adding `sunmi_printer_plus`, verify:

- supported platforms
- Flutter 3.32.7 compatibility
- Android SDK requirements
- transitive dependency impact
- impact on Web/Desktop builds
- impact on eventual pub.dev publication

If direct inclusion harms cross-platform compatibility, isolate Sunmi behind a separate adapter/package or platform implementation.

Capabilities:

- print
- cut when supported
- cash drawer when supported

Commit:

```text
feat(printer): add Sunmi adapter
```

## 12. Hardware capabilities

Do **not** put cut or cash-drawer commands in `PdfRenderService`.

PDF rendering and physical hardware control are separate responsibilities.

Model optional capabilities such as:

```dart
abstract interface class CutterCapability {
  Future<void> cutPaper();
}

abstract interface class CashDrawerCapability {
  Future<void> openCashDrawer();
}
```

Implement only in compatible printer adapters.

Unsupported operations must report capability absence cleanly.

Commit:

```text
refactor(printer): model hardware capabilities
```

---

# PHASE 4 — HARDENING

## 13. CI

Update `.github/workflows/ci.yml` using Flutter **3.32.7**.

The current CI already has native Designer build gates. **Preserve them.** Task 13 may strengthen or reorganize CI, but must not reduce existing platform compile coverage.

### report_engine

- pub get
- format check
- analyze
- unit tests

### designer quality

- pub get
- format check
- analyze
- tests

### designer build matrix — required to retain

- Web release build
- Android APK build
- Linux release build
- Windows release build
- macOS release build
- iOS simulator build

### example

- pub get
- analyze
- tests where available
- build Android APK

The example APK is an additional gate and does **not** replace any Designer native build job.

Use dependency caching where appropriate.

CI must fail on analyzer errors, failing tests, or required build-gate failures.

Commit:

```text
ci: validate engine designer and example
```

## 14. Rendering regression tests

Create deterministic fixtures for:

- Thermal 80mm
- Thermal 58mm
- A4 invoice with 25+ rows
- Thai invoice

If deterministic PDF-byte comparison is unreliable because of metadata/object ordering, compare stable properties instead:

- valid PDF structure
- page count
- expected page dimensions
- expected render/content operations
- rendered-image golden where feasible

`bytes.length > 0` alone is not a golden test.

Commit:

```text
test(pdf): add rendering regression coverage
```

## 15. Documentation

Create/update:

```text
docs/PRINTER_COMPATIBILITY.md
```

Separate status into:

- Implemented
- Automated test coverage
- Emulator/simulator verified
- Physically tested

Candidate printers:

- XP-80
- XP-58
- Epson TM-T88V
- Sunmi V2

Document:

- connection type
- Thai strategy
- code page
- cut support
- cash drawer support
- known limitations

Never mark a printer as physically tested without actual hardware evidence.

Update:

```text
docs/CODE_WALKTHROUGH.md
```

with the new architecture/services.

Commit:

```text
docs: update printer compatibility and walkthrough
```

---

# PHASE 5 — RELEASE

## 16. Prepare `report_engine` for pub.dev

Review `packages/report_engine/pubspec.yaml`.

The package currently uses `publish_to: none`; remove it only when the package is actually ready for publication.

Verify/add:

- description
- repository
- homepage where appropriate
- issue_tracker
- topics
- license
- README
- CHANGELOG

Run publish dry-run using the correct package command.

Resolve material publish warnings.

Ensure publication excludes:

- generated build output
- IDE files
- oversized test artifacts
- credentials/secrets

Commit:

```text
chore(engine): prepare pub.dev release
```

## 17. Designer Web deployment

Add Firebase Hosting configuration for `apps/designer`.

Firebase Hosting is deployment infrastructure only; the application must remain backend-free at runtime.

Verify:

- correct Flutter web base path
- SPA fallback where required
- appropriate caching for versioned Flutter assets
- deployment instructions

Build:

```bash
flutter build web
```

Do not claim deployment success without valid credentials and an actual successful deployment.

Commit:

```text
chore(designer): configure Firebase Hosting
```

---

# RELEASE GATE — v1.0.0

Before declaring Production v1.0.0 complete, verify:

- [ ] repository clean
- [ ] format checks pass
- [ ] analyzer passes
- [ ] all automated tests pass
- [ ] Designer Web builds
- [ ] Designer Android APK builds
- [ ] Designer Linux build passes
- [ ] Designer Windows build passes
- [ ] Designer macOS build passes
- [ ] Designer iOS simulator build passes
- [ ] Example Android APK builds
- [ ] package publish dry-run passes
- [ ] bundled Thai PDF rendering works
- [ ] ESC/POS Thai encoding tests pass
- [ ] save/load round trip passes
- [ ] import/export round trip passes
- [ ] undo/redo tests pass
- [ ] A4 multi-page output passes

Hardware-dependent functionality must remain labeled:

```text
NEEDS PHYSICAL VERIFICATION
```

until verified with actual hardware.

Create:

```text
docs/RELEASE_CHECKLIST_v1.0.0.md
```

Do not mark v1.0.0 production-ready while mandatory non-hardware release gates are failing.

---

# Execution Protocol

For every numbered task:

1. Inspect relevant existing code.
2. State briefly what will change.
3. Implement.
4. Format.
5. Analyze.
6. Run relevant tests/builds.
7. Fix regressions.
8. Summarize changed files and validation results.
9. Commit only that task with the specified conventional commit message.
10. Continue to the next task automatically.

Do not stop merely because implementation differs from the roadmap if a better architectural equivalent satisfies the requirement.

Stop only for:

- unavailable credentials required for deployment/publishing
- physical hardware verification
- destructive or irreversible operation
- unrecoverable external dependency problems

In those cases, complete everything else possible and record the blocker explicitly.

## Next Action

PRE-FLIGHT is complete. Continue with **Phase 1 / Task 1 — Verify and preserve runnable Designer platforms**.
