# Flutter Report Suite Designer — Stitch UI Implementation Plan

This plan turns the normalized Stitch handoff into incremental Flutter changes without rewriting the working report engine or document controller.

Last updated: **2026-08-31**

## Scope guard

This is a **visual-system migration first**. Existing functional behavior is source-of-truth. Stitch screens contain aspirational interactions that may require later model work; visual refactoring must not falsely expose unsupported features.

## Status summary

- P0 — baseline/regression capture: ✅ complete
- P1 — tokens/theme foundation: ✅ complete
- P2 — shared controls: ✅ complete
- P3 — app shell: ✅ complete
- P4 — canvas visual layer: ✅ complete
- P5 — inspector migration: ✅ complete
- P6 — left panel + Layers/Data shell: ✅ complete
- P7 — Template Gallery migration: ✅ complete
- P8 — Table UX expansion: ✅ complete
- P9 — Unified Preview workspace: ✅ complete

The normalized **Stitch UI modernization plan ends at P9**. A separate post-release **P10 — Printing Architecture & Printer Profiles** roadmap is now defined in `docs/PROJECT_HANDOFF.md`; it is not an extension of the Stitch visual migration sequence.

## P1 — Tokens and theme foundation

Delivered semantic color, typography, spacing, radius, layout, and elevation tokens plus `DesignerTheme.light()`.

## P2 — Shared controls

Delivered reusable controls including toolbar buttons, panel headers, inspector sections, property inputs/dropdowns/toggles, zoom, and inline alerts.

## P3 — App shell

Delivered `DesignerAppShell` with toolbar, left panel, inspector, status bar, responsive collapse behavior, and preserved document actions/shortcuts.

## P4 — Canvas visual layer

Delivered `CanvasViewport`, rulers, page, guide overlay, selection overlay, and preserved physical-mm calculations / zoom behavior.

## P5 — Inspector migration

Migrated model-backed properties only: content/key, geometry, font size, bold, alignment, and table columns.

Unsupported Stitch-only controls remain intentionally absent until backed by real model/API support.

## P6 — Left panel + Layers/Data shell

Delivered Add Element migration plus Elements/Layers/Data shell with capability-appropriate states.

## P7 — Template Gallery visual migration

Delivered shared typography/color/button/search/card patterns while preserving built-in template loading and editable working-copy semantics.

## P8 — Table UX expansion

Delivered model-backed table editing improvements without falsely exposing unsupported expression/pagination concepts.

Merge SHA:

```text
18331aa9d667771ee4878b5e0c34db327bc9f774
```

## P9 — Unified Preview workspace

**Status: ✅ COMPLETE — 2026-08-13**

P9 was split into two merge-safe steps.

### P9A — PDF / system print foundation

PR #19.

Merge SHA:

```text
99e0785c3a4032400c8c519102b5e2c0de5baa32
```

Delivered:

- unified `PreviewWorkspacePage`
- shared Designer shell/settings/status/alert primitives
- generated PDF from existing report engine functionality
- platform System Print
- actual paper metadata and PDF byte status
- compact fallback layout

Validation: CI run #138 passed the full matrix.

### P9B — ESC/POS preview mode

PR #20.

Validated head:

```text
4cd8973b1cc66b32a3173519c877a3c50333267b
```

Merge SHA:

```text
9cfd4a3b31f69163c37aea13be4087cfa9e74d15
```

Delivered:

- `EscPosPreviewPanel`
- PDF ↔ ESC/POS mode switching
- rendered byte count + bounded hex preview
- real `EscPosRenderer.renderTemplate()` integration
- `ReportTemplate.fromJson(...)` integration using current Designer document/data
- System Print unavailable in ESC/POS mode
- ESC/POS selector absent when no rendered payload exists
- ESC/POS generation limited to thermal documents at the Designer boundary
- no implicit transport send
- no invented cutter/cash-drawer/status capability UI

Validation: CI run #147 / run id `31685965055` passed the full nine-job Flutter 3.32.7 matrix.

## Hardware capability rule

Hardware capability UI must use actual contracts from `report_engine` / adapters.

Current generic optional hardware contracts are limited to:

- `CutterCapability`
- `CashDrawerCapability`

Actual ESC/POS sending requires a selected `EscPosTransport`.

Do not infer connected/status/encoding/cutter/drawer support where no contract or verified adapter capability exists.

## Validation gates after every future P-step

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter build web --release --base-href /flutter_report_suite/` at major shell milestones
- retain the existing six-platform CI matrix before merge

## Completed branch sequence

1. `agent/designer-ui-foundation`
2. `agent/designer-ui-shell-canvas`
3. inspector/gallery follow-up branches
4. `agent/designer-ui-data-table`
5. `agent/designer-ui-preview`
6. `agent/designer-ui-preview-escpos`

## Next implementation target

No further target exists **inside the Stitch UI modernization plan**; that sequence is complete at P9.

After the v1.0.0 release actions are complete, continue with the separate P10 roadmap defined in `docs/PROJECT_HANDOFF.md`, beginning with its P0 architecture items. Do not treat P10 as a Stitch design phase.
