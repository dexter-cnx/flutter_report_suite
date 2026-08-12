# Phase 4 Hardening Validation

This file records the intended validation scope for Tasks 13–15.

## Task 13 — CI hardening

The GitHub Actions workflow now includes explicit quality gates for:

- `packages/report_engine`
- `packages/report_engine_sunmi`
- `apps/designer`
- `packages/report_engine/example`

Each quality scope runs dependency resolution, formatting checks, analysis, and tests. The example job also builds an Android debug APK.

The Designer build matrix remains:

- Web release
- Android APK
- Linux release
- Windows release
- macOS release
- iOS simulator

Reference Flutter version: **3.32.7**.

## Task 14 — Rendering regression tests

`packages/report_engine/test/pdf_render_service_test.dart` now protects stable rendering properties for:

- Thermal 80mm PDF
- Thermal 58mm PDF
- A4 geometry
- A4 invoice with more than 25 rows and multi-page pagination
- Thai A4 invoice

The tests use PDF structure, page count, `/MediaBox` geometry, and output-size sanity checks rather than raw PDF byte equality.

Raw byte equality is intentionally avoided because generated PDFs include dynamic values such as print timestamps and may contain nondeterministic metadata/object ordering.

## Task 15 — Documentation

Added/updated:

- `docs/PRINTER_COMPATIBILITY.md`
- `docs/CODE_WALKTHROUGH.md`

The compatibility document separates implemented software behavior from automated evidence and physical printer verification.

Candidate hardware remains **NEEDS PHYSICAL VERIFICATION** until real-device evidence is recorded.

## Validation state

Repository-side implementation is complete on the Phase 4 branch. GitHub CI on the Phase 4 pull request is the authoritative multi-runner validation gate for Linux/Windows/macOS/iOS/Web/Android coverage.

No physical-printer claim is made by this document.
