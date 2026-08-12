# Flutter Report Suite Designer — Stitch UI Implementation Plan

This plan turns the normalized Stitch handoff into incremental Flutter changes without rewriting the working report engine or document controller.

## Scope guard

This is a **visual-system migration first**. Existing functional behavior is source-of-truth. Stitch screens contain aspirational interactions that may require later model work; visual refactoring must not falsely expose unsupported features.

## P0 — Baseline and regression capture

- capture current Designer/gallery screenshots or goldens at representative desktop widths
- identify widget tests tied to labels/layout
- keep all current Designer tests passing
- confirm `flutter analyze`, tests, and web build before visual changes

Exit: baseline evidence exists and no behavior changes.

## P1 — Tokens and theme foundation

Add `lib/design_system/` with semantic color, typography, spacing, radius, layout, and elevation tokens.

Update `main.dart` from bare `colorSchemeSeed` styling to `DesignerTheme.light()` while retaining Material 3 integration.

Do not redesign pages yet; first make primitives available.

Exit: theme/tokens compile, analyzer/tests pass.

## P2 — Shared controls

Implement and test:
- `ToolbarButton`
- `PanelHeader`
- `InspectorSection`
- `PropertyInput`
- `NumberPropertyInput`
- `PropertyDropdown`
- `PropertyToggle`
- `ZoomControl`
- `InlineAlert`

Exit: components have widget tests for canonical sizing and key states.

## P3 — App shell

Refactor `DesignerPage` to `DesignerAppShell` structure:
- 56 px toolbar
- 264 px left panel
- 320 px inspector
- 32 px status bar
- center canvas priority
- responsive panel-collapse strategy

Preserve all document actions and shortcuts.

Exit: no save/load/import/export/undo/redo regression; wide/narrow widget tests pass.

## P4 — Canvas visual layer

Extract:
- `CanvasViewport`
- `CanvasRuler`
- `CanvasPage`
- `CanvasGuideOverlay`
- `CanvasSelectionOverlay`

Keep `DesignerDocumentController` physical-mm calculations unchanged unless a correctness issue is discovered.

Move visible zoom to shared `ZoomControl` and status bar. Preserve 50–200% behavior.

Exit: drag, snap, rulers, center guides, zoom, keyboard nudge and undo tests pass.

## P5 — Inspector migration

Replace ad-hoc property widgets with normalized primitives. Split current single property list into collapsible sections.

For current model, first expose only supported fields:
- content/key
- X/Y/W/H
- font size
- bold
- alignment
- table columns

Do not add unsupported fill/stroke/expression UI merely because Stitch shows it.

Exit: property edits and table-column tests pass.

## P6 — Left panel + Layers/Data shell

Migrate Add Element rows into `ToolPanelItem` and add tab structure for Elements/Layers/Data.

Elements can ship first. Layers/Data tabs may show capability-appropriate states until their full interactions are implemented.

Exit: adding all current element types remains functional.

## P7 — Template Gallery visual migration

Apply shared typography/color/button/search/card patterns to `TemplateGalleryPage` while preserving built-in template loading and editable working-copy semantics.

Exit: gallery responsive tests and open-template flow pass.

## P8 — Table UX expansion

After visual migration is stable, implement only model-backed Table Editor improvements. Track unsupported Stitch concepts separately:
- contextual toolbar
- direct column resize
- cell selection
- repeating-row visualization
- pagination controls
- expressions

These require explicit data-model/API design before UI exposure.

## P9 — Unified Preview workspace

Build PDF/system print preview shell around existing engine functionality, then ESC/POS mode. Reuse shared settings/alert/status/zoom primitives.

Hardware capability UI must use actual capability contracts from `report_engine` / adapters.

## Validation gates after every P-step

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter build web --release --base-href /flutter_report_suite/` at major shell milestones
- retain existing six-platform CI matrix before merge of the full visual phase

## Suggested branch sequence

1. `agent/designer-ui-foundation`
2. `agent/designer-ui-shell-canvas`
3. `agent/designer-ui-inspector-gallery`
4. `agent/designer-ui-data-table`
5. `agent/designer-ui-preview`

Do not mix all visual and model-expansion work into one PR.

## First implementation target

Start with **P1 + P2 only** after this documentation handoff is reviewed. They are low-risk and establish the source of truth required by every later screen.
