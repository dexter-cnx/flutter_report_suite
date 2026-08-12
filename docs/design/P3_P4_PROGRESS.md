# Designer P3/P4 Progress

This branch establishes the reusable visual primitives required for the next Designer migration step.

## P3 — App Shell foundation

Added:

- `DesignerAppShell`
- canonical 56 px toolbar slot
- canonical 264 px left-panel slot
- canonical 320 px right-inspector slot
- canonical 32 px status-bar slot
- `DesignerStatusBar`

The existing `DesignerPage` is intentionally not migrated in this commit set. Keeping the shell primitive isolated first gives CI and widget tests a stable contract before the large page refactor.

## P4 — Canvas foundation

Added:

- `CanvasViewport`
- `CanvasPage`
- `CanvasRuler`
- `CanvasGuideOverlay`
- `CanvasSelectionOverlay`

These primitives preserve the current Designer concepts: millimeter rulers, disabled InteractiveViewer scaling, center guides, printable page dimensions, and selection handles.

## Next migration step

Refactor `DesignerPage` to compose these primitives while preserving existing behavior:

1. replace the `AppBar`/wide `Row` with `DesignerAppShell`
2. move current toolbar actions into the shell toolbar
3. replace hard-coded 190/310 px panels with tokenized panel slots
4. replace current canvas `ColoredBox` + `InteractiveViewer` with `CanvasViewport`
5. replace inline rulers/page/guides/selection borders with canvas primitives
6. add the real status bar with paper/zoom/snap state
7. rerun existing Designer interaction tests before changing inspector behavior

No report schema or document-controller behavior changes are part of this foundation step.
