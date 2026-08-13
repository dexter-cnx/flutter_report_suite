# Designer design-system primitives

The design-system layer contains reusable shell, control, inspector, left-panel, and canvas primitives derived from the normalized Stitch handoff.

Use `DesignerAppShell` for the canonical desktop frame and `CanvasViewport` / `CanvasPage` / `CanvasRuler` / `CanvasGuideOverlay` / `CanvasSelectionOverlay` for Designer canvas composition.

Use `DesignerLeftPanel` for the Elements / Layers / Data mode shell and `ToolPanelItem` for addable report-element rows. Layers and Data content must remain model-backed: do not expose reorder, visibility, locking, or data-tree binding interactions until the report model supports them.

Keep document-controller behavior outside these widgets. Design-system primitives own visual/layout contracts and interaction affordances, while `DesignerPage` continues to route mutations through `DesignerDocumentController`.
