# Designer design-system primitives

The design-system layer now contains reusable shell, control, and canvas primitives derived from the normalized Stitch handoff.

Use `DesignerAppShell` for the canonical desktop frame and `CanvasViewport` / `CanvasPage` / `CanvasRuler` / `CanvasGuideOverlay` / `CanvasSelectionOverlay` for Designer canvas composition.

Keep document-controller behavior outside these widgets. These primitives are visual/layout contracts only.
