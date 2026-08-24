# v1.0.0 Release Audit

Last updated: 2026-08-24

## Purpose

This document is the execution checklist for the remaining Flutter Report Suite v1.0.0 release actions after completion of the Designer Stitch modernization plan.

## Verified repository state

- Default branch: `main`
- Audited `main` commit: `1c96807d7b1bdc01dd93611fd47aa156b80e0bb5`
- No open pull requests were present at audit start.
- Designer Stitch modernization P0-P9 is documented as complete.
- `report_engine` is versioned as the v1.0.0 publication candidate in the existing handoff.
- `report_engine_sunmi` remains intentionally unpublished for this release cycle.
- The existing handoff records passing format/analyze/test/build/publish-dry-run gates and the six-platform Designer matrix.

## Release actions

### R1 — Freeze release source

Target the v1.0.0 tag at the validated `main` release commit only after the final release audit is merged.

Do not tag an unreviewed documentation/audit branch.

### R2 — GitHub tag and release

Required evidence:

- tag `v1.0.0`
- GitHub Release `v1.0.0`
- release notes describing report engine, Designer, Thai PDF/ESC-POS support boundaries, and hardware-verification caveats
- release target commit recorded in this document and `PROJECT_HANDOFF.md`

### R3 — pub.dev publication

Publish only:

```text
packages/report_engine
```

Required pre-publication checks:

```bash
cd packages/report_engine
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter pub publish --dry-run
```

The actual `flutter pub publish` step requires pub.dev credentials/authorization from the maintainer environment. Do not mark publication complete from dry-run evidence alone.

### R4 — Post-publication verification

After publication, record:

- pub.dev package URL
- published version `1.0.0`
- publication timestamp
- package score/analysis status once available
- install smoke test from a clean consumer project if practical

### R5 — Physical printer evidence

Physical printer verification remains separate from the software release. Do not block the software tag/release solely on unavailable hardware, but do not claim specific hardware models as physically verified without evidence.

Track real-device results in `docs/PRINTER_COMPATIBILITY.md`.

## Current evidence and blockers

| Item | State | Evidence / next action |
| --- | --- | --- |
| P0-P9 Designer modernization | Complete | `docs/design/IMPLEMENTATION_PLAN.md` |
| v1 software quality gates | Previously validated | `docs/PROJECT_HANDOFF.md` |
| Open PR audit | Clear at audit start | No open PRs found on 2026-08-24 |
| Final release-audit PR | In progress | `agent/v1-release-audit` |
| `v1.0.0` tag | Not yet recorded | Create only after audit merge |
| GitHub Release | Not yet recorded | Create after tag |
| `report_engine` pub.dev publication | Not yet verified | Requires maintainer pub.dev authorization |
| `report_engine_sunmi` publication | Intentionally deferred | Keep unpublished |
| Physical printer matrix | Partial / pending | Record real hardware evidence separately |

## Release note draft

### Flutter Report Suite v1.0.0

First production release of the offline-first Flutter Report Suite.

Highlights:

- visual report Designer with JSON template persistence
- reusable `report_engine` package
- PDF rendering including bundled Thai fonts
- ESC/POS rendering with TIS-620, CP874 and rasterized Thai strategies
- table column editing and report data binding
- unified PDF/System Print and ESC/POS preview workspace
- Web, Android, iOS, Linux, macOS and Windows Designer build coverage
- optional Sunmi integration kept in a separate package boundary

Hardware note: software support and physical-printer verification are tracked separately. Specific printer models must not be treated as physically verified unless evidence is recorded in `docs/PRINTER_COMPATIBILITY.md`.

## Exit criteria

The v1.0.0 release work is complete only when all applicable evidence below is recorded:

- [ ] final release audit merged to `main`
- [ ] final release-source CI is green
- [ ] `v1.0.0` tag exists and points to the intended release commit
- [ ] GitHub Release exists
- [ ] `report_engine` 1.0.0 is published on pub.dev
- [ ] pub.dev URL/version recorded in the handoff
- [ ] `report_engine_sunmi` remains unpublished unless explicitly approved
- [ ] post-release handoff updated with concrete evidence
