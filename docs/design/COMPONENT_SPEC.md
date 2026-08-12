# Flutter Report Suite Designer — Component Specification

This inventory maps the Stitch visual system onto reusable Flutter widgets. Implementation should prefer composable primitives over one widget per screenshot fragment.

## Shell components

### `DesignerAppShell`
Shared desktop application frame containing `DesignerToolbar`, optional left panel, center workspace slot, optional inspector, and `DesignerStatusBar`.

States: full, left-collapsed, inspector-collapsed, compact-width.

### `DesignerToolbar`
Height: 56 px. Use for global actions only: document name/state, undo/redo, preview, save/export/print, overflow. Table/cell-only actions belong in a contextual toolbar.

### `DesignerStatusBar`
Height: 32 px. Shared across Designer and Preview. Supports paper/page state, snap/guides, output mode, and zoom.

## Panel components

### `DesignerPanel`
Structural side surface with zero radius, no shadow, 1 px separator.

### `PanelHeader`
Height: 32 px; title + optional actions.

### `InspectorSection`
Collapsible property group. Header is 32 px class, 1 px divider, 12 px horizontal content padding, 8 px typical row gap. Variants: standard, warning-bearing, read-only.

### `PropertyRow`
Two-column label/value layout for dense property editing.

### `PropertyInput`
Compact text field. Default 28 px in Inspector, 32 px elsewhere.

### `NumberPropertyInput`
Numeric validation, optional unit suffix, arrow increment/decrement, future scrub behavior.

### `PropertyDropdown`
Compact single-value selector; replaces ad-hoc `DropdownButtonFormField` styling.

### `PropertyToggle`
Compact switch/checkbox row; avoid full `CheckboxListTile` density in Inspector.

### `SegmentedControl`
For small mutually exclusive modes such as Design/Data/Advanced or Preview mode.

## Tree/list components

### `ToolPanelItem`
Draggable/addable element such as Text, Table, QR, Barcode.

### `TreeRow`
Base hierarchy row with indentation, expand/collapse, icon, label, optional trailing actions.

### `LayerRow`
`TreeRow` specialization with selected, locked, visible, and reorder states.

### `DataFieldRow`
`TreeRow` specialization with data-type icon, data path, draggable state, bound state.

### `DataBindingBadge`
Small consistent indicator for bound fields/expressions/repeating data. Use the Indigo semantic accent only.

## Canvas components

### `CanvasViewport`
Owns workspace background, pan/zoom, centering, viewport clipping, and overlays.

### `CanvasRuler`
Shared horizontal/vertical mm ruler; replaces current independent ad-hoc ruler widgets.

### `CanvasPage`
Printable page surface. Receives physical-mm dimensions and converts through viewport scale.

### `CanvasSelectionOverlay`
Selection border, handles, dimensions, and context affordances. Selection decoration must not be embedded into report element content.

### `CanvasResizeHandle`
8×8 canonical handle.

### `CanvasGuideOverlay`
Center guides, smart alignment guides, snap guides, margins, and future distance labels.

### `ZoomControl`
Shared by Designer and Preview: zoom out/current/zoom in and fit modes.

## Table components

### `TableContextToolbar`
Contextual row/column/cell actions; visible only with table context.

### `TableInspector`
Composition of standard `InspectorSection`s. Contexts: table, column, row, cell, multi-cell.

### `TableColumnRow`
Replaces each current table-column `Card`; uses standard property fields and reorder/delete actions.

### `TableSelectionOverlay`
Extends normal selection with active cell, row/column handles, resize guides.

## Preview/output components

### `PreviewWorkspace`
Shared center workspace for PDF, system-printer, and ESC/POS modes.

### `PreviewToolbar`
Uses standard toolbar primitives; contains back, mode switcher, navigation, primary output action.

### `OutputSettingsPanel`
320 px Inspector-style panel using `InspectorSection` and standard properties.

### `OutputCheck`
Compact pre-flight list with success/warning/error rows.

### `PrinterProfileSelector`
Printer/profile selector with readiness state and capability summary.

### `PageNavigation`
Page X/Y + previous/next/first/last where relevant.

## Feedback components

### `InlineAlert`
Contextual warning/error/info with optional action. Preferred for binding, printable-area, expression, and printer-profile issues.

### `DesignerToast`
Short save/export success/failure feedback. Use instead of generic SnackBar when the visual migration touches that flow.

### `DesignerEmptyState`
Compact icon/title/body/action pattern; no decorative illustration requirement.

### `DesignerDialog`
400–520 px normal modal width. Use only for interruptive flows.

### `DesignerSideSheet`
For data source, printer profile, advanced export, or settings that need room without hiding the workspace.

## Current-code migration targets

| Current implementation | Target component |
|---|---|
| `Scaffold` + `AppBar` in `DesignerPage` | `DesignerAppShell` + `DesignerToolbar` |
| `SizedBox(width: 190)` left panel | canonical `DesignerLeftPanel` at 264 px |
| grey `Material` panel surfaces | `DesignerPanel` |
| `ListTile` add buttons | `ToolPanelItem` |
| paper/zoom controls mixed into left panel | inspector/status/`ZoomControl` according to function |
| `InteractiveViewer` wrapper | retained inside `CanvasViewport` |
| `_horizontalRuler` / `_verticalRuler` | `CanvasRuler` |
| selection border inside `_positionedElement` | `CanvasSelectionOverlay` |
| `SizedBox(width: 310)` right panel | `DesignerInspector` at 320 px |
| plain `TextFormField` properties | `PropertyInput` / `NumberPropertyInput` |
| `CheckboxListTile` | `PropertyToggle` |
| `DropdownButtonFormField` | `PropertyDropdown` |
| table column `Card` | `TableColumnRow` inside `InspectorSection` |
| toolbar `IconButton` | `ToolbarButton` |
| `PopupMenuButton` | standard command/menu surface |
| gallery `SnackBar` | `DesignerToast` / `InlineAlert` by context |
| template `Card` | tokenized `TemplateCard` |

## Implementation constraint

Do not create these components merely as wrappers around existing one-off styling. Each primitive should own canonical density, state styling, semantics, and tests so later screens reuse behavior rather than copy constants.
