# Phase 3 Tasks 9–12 Validation

Date: 2026-08-12
Branch: `agent/phase-3-printer-engine`
Flutter baseline: 3.32.7

## Status

Tasks 9–12 have completed implementation and maintainer-confirmed local validation.

This document records software validation only. It does **not** claim physical printer compatibility.

## Task 9 — Thai ESC/POS

Validated implementation scope:

- configurable Thai strategies: TIS-620, CP874, raster image fallback
- code-page encoding isolated from transport
- raster Thai rendering through bundled Noto Sans Thai fonts
- ESC/POS renderer separated from Bluetooth transport
- required Thai fixtures and mixed-content tests
- example application ESC/POS generation path

Physical verification still required before claiming compatibility for any specific printer model/code-page combination.

## Task 10 — Unified Printer Discovery

Validated implementation scope:

- `UnifiedPrinter` domain model
- system and Bluetooth discovery sources
- deterministic IDs where available
- source error isolation
- deduplication
- deterministic ordering
- optional additional discovery sources for platform-specific adapters

Note: current Bluetooth implementation uses `flutter_blue_plus` and therefore covers BLE, not Bluetooth Classic.

## Task 11 — Sunmi adapter

Sunmi integration is isolated in:

`packages/report_engine_sunmi`

Validated implementation scope:

- dependency resolution with `sunmi_printer_plus ^4.1.1`
- analyzer clean
- package tests passing
- raw ESC/POS transport adapter
- embedded printer discovery source
- cut / cash drawer bridge methods
- printer service rebind support
- post-Task-12 capability-interface validation passed

The adapter remains Android-specific by design so the core `report_engine` package does not acquire an Android-only plugin dependency.

Physical Sunmi hardware verification is still pending.

## Task 12 — Hardware capabilities

Validated implementation scope:

- `CutterCapability` and `CashDrawerCapability` are defined in core
- ESC/POS rendering contains no implicit cut command
- `EscPosPrinterService` no longer synthesizes cutter commands
- cut is executed only through an explicit `CutterCapability`
- requesting cut without a supplied cutter fails before payload transmission
- Sunmi adapter implements cutter and cash-drawer capability contracts
- capability tests verify `send -> cut` ordering

## Maintainer-confirmed validation

### Core package

```bash
cd packages/report_engine
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Result: PASS

### Example application

```bash
cd packages/report_engine/example
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Result: PASS

### Sunmi companion package

```bash
cd packages/report_engine_sunmi
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Result: PASS

## Phase 3 conclusion

Phase 3 Tasks 9–12 are implementation + local validation complete.

The branch may proceed to PR review and CI. Per the phase-boundary rule, Phase 4 must not start until the Phase 3 PR is reviewed, CI is green, and the branch is merged into `main`.

Physical printer validation remains a separate evidence track and must not be inferred from automated/local software validation.
