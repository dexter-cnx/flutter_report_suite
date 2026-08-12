# Flutter Report Suite Designer — Screen Mapping

## 1. Template Gallery

Current code: `apps/designer/lib/pages/template_gallery_page.dart`

Target hierarchy:

```text
DesignerAppShell
├─ DesignerToolbar
│  ├─ ProductTitle
│  ├─ SearchField (when gallery scope grows)
│  └─ primary/overflow actions
├─ TemplateGalleryWorkspace
│  └─ TemplateGrid
│     ├─ BlankTemplateCard
│     └─ TemplateCard × N
└─ DesignerStatusBar (optional; omit if it adds no value)
```

Migration notes:
- retain current built-in templates and editable working-copy behavior
- replace generic Material `Card` visuals with tokenized `TemplateCard`
- keep responsive 4/2/1-column behavior conceptually, aligned with final Stitch spacing/proportions
- migrate open failures to the standard feedback primitive

## 2. Report Designer

Current code: `apps/designer/lib/pages/designer_page.dart`

```text
DesignerAppShell
├─ DesignerToolbar
│  ├─ DocumentTitleState
│  ├─ Undo/Redo
│  ├─ Preview
│  ├─ Save/Export
│  └─ CommandMenu
├─ DesignerLeftPanel
│  ├─ PanelModeTabs [Elements, Layers, Data]
│  └─ panel content
├─ CanvasViewport
│  ├─ CanvasRuler(horizontal)
│  ├─ CanvasRuler(vertical)
│  ├─ CanvasPage
│  │  └─ ReportElementView × N
│  ├─ CanvasGuideOverlay
│  └─ CanvasSelectionOverlay
├─ DesignerInspector
│  ├─ InspectorSection(Transform)
│  ├─ InspectorSection(Content/Data)
│  ├─ InspectorSection(Typography)
│  ├─ InspectorSection(Appearance)
│  └─ context-specific sections
└─ DesignerStatusBar
   ├─ paper/page info
   ├─ snap/guides
   └─ ZoomControl
```

Preserve current behavior: physical-mm persistence, 5 mm snap, rulers, zoom 50–200%, grouped drag undo, keyboard undo/redo/delete/nudge, template persistence/import/export.

## 3. Table Editor

The current table editor is embedded in the right panel and edits column key/label/width/alignment.

Target hierarchy:

```text
ReportDesignerShell
├─ TableContextToolbar
├─ CanvasViewport
│  └─ TableSelectionOverlay
└─ DesignerInspector
   ├─ InspectorSection(Table)
   ├─ InspectorSection(Data)
   ├─ InspectorSection(Header)
   ├─ InspectorSection(Footer)
   ├─ InspectorSection(Cell Defaults)
   └─ InspectorSection(Pagination)
```

Near-term migration must keep the current Phase-2 table data model. Stitch-only concepts such as merge/split cells, repeating-row UX, rich pagination controls, and expressions are design targets, not claims that the model already implements them.

## 4. Data Binding

Current implementation supports dynamic keys/templates and mock data but does not yet have the full Stitch Data Explorer UI.

```text
DesignerLeftPanel(mode=Data)
└─ DataTree
   ├─ DataFieldRow(object)
   ├─ DataFieldRow(array)
   └─ DataFieldRow(value)

DesignerInspector
└─ InspectorSection(Data Binding)
   ├─ BindingMode
   ├─ DataPathSelector
   ├─ FormatSelector
   └─ validation
```

Add incrementally after shell primitives exist.

## 5. PDF / System Print Preview

Current `DesignerPage._previewPdf` generates PDF bytes through `FlutterReportPrinter.generatePdf`, then pushes a preview route containing the `printing` package `PdfPreview` widget. The existing preview UI therefore already owns print/share behavior and must remain the baseline until the future unified preview shell deliberately replaces it. `Printing.layoutPdf` is only used by the separate `FlutterReportPrinter.preview` helper and is not the current Designer preview path.

```text
PreviewWorkspace
├─ PreviewToolbar
│  ├─ BackToDesigner
│  ├─ PreviewModeSelector
│  ├─ PageNavigation
│  ├─ ZoomControl
│  └─ OutputAction
├─ PreviewCanvas
│  └─ PagePreview × N
├─ OutputSettingsPanel
│  ├─ InspectorSection(Document)
│  ├─ InspectorSection(Page Range)
│  ├─ InspectorSection(Printer/Output)
│  └─ OutputCheck
└─ DesignerStatusBar
```

This is a future UI shell around existing report-engine/printing functionality; preserve the current `PdfPreview` route and its print/share behavior until that shell is implemented and validated.

## 6. ESC/POS Preview

```text
PreviewWorkspace(mode=escpos)
├─ PreviewToolbar
├─ ReceiptPreviewCanvas
├─ OutputSettingsPanel
│  ├─ PrinterProfileSelector
│  ├─ InspectorSection(Paper/Encoding)
│  ├─ InspectorSection(Cutter)
│  ├─ InspectorSection(Cash Drawer)
│  ├─ InspectorSection(Feed/Image)
│  └─ OutputCheck
└─ DesignerStatusBar
```

Hardware capabilities must continue to come from verified capability models. The UI must not infer cutter/cash-drawer support from printer names.

## Shared screen primitives

| Component | Gallery | Designer | Table | Data | PDF/Print | ESC/POS |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| DesignerToolbar | ✓ | ✓ | ✓ | ✓ | derivative | derivative |
| DesignerPanel |  | ✓ | ✓ | ✓ | ✓ | ✓ |
| InspectorSection |  | ✓ | ✓ | ✓ | ✓ | ✓ |
| Property controls |  | ✓ | ✓ | ✓ | ✓ | ✓ |
| Canvas/Preview workspace token system |  | ✓ | ✓ | ✓ | ✓ | ✓ |
| ZoomControl |  | ✓ | ✓ | ✓ | ✓ | optional |
| DesignerStatusBar | optional | ✓ | ✓ | ✓ | ✓ | ✓ |
| InlineAlert | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| DesignerToast | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
