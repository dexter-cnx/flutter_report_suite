# Flutter Report Suite Designer — Interaction Specification

## Global states

Every interactive control must define default, hover, pressed, focused, and disabled states. Selection-capable controls also define selected. Drag sources/targets define dragging, valid-drop, and invalid-drop.

Focus remains visible for keyboard users and should use a 2 px primary ring without changing layout.

## Keyboard model

Preserve existing working shortcuts:
- Ctrl/Cmd+Z: undo
- Ctrl/Cmd+Shift+Z: redo
- Delete/Backspace: delete selection
- arrows: nudge selection

Target additions during visual refactor:
- Ctrl/Cmd+S: save
- Ctrl/Cmd+C / V: copy/paste when document model supports it
- Ctrl/Cmd+D: duplicate selection
- Ctrl/Cmd+P: print/preview entry
- Ctrl/Cmd+Shift+E: export
- Space+drag: pan canvas
- Ctrl/Cmd + wheel: zoom

Do not add visual shortcut claims before behavior exists.

## Canvas

### Selection
- selected element: 1 px primary outline
- 8 px handles rendered by overlay, not inside report element content
- element selection must not change printable content bounds

### Drag
- preserve grouped drag transaction/undo behavior already provided by `DesignerDocumentController`
- canvas feedback uses guide overlay; persisted physical-mm values must remain independent of zoom

### Snap/guides
- preserve current 5 mm snap behavior
- center guides remain available
- future smart guides use the same accent token and overlay layer

### Zoom
- keep persistence independent of zoom
- `ZoomControl` owns visible zoom and fit commands
- move visible zoom from left properties toward status/toolbar placement according to final shell

## Left panel

Modes: Elements, Layers, Data. Use a single left-panel shell rather than separate permanent panes.

Rows:
- hover: `surfaceHover`
- selected: `primarySubtle`
- dragging: source slightly elevated/faded
- valid canvas target: precise primary drop indicator

## Inspector

Inspector context follows selection. No selection shows a compact useful empty state rather than a large blank panel.

Sections are collapsible. Normal property editing happens inline; avoid modal dialogs for X/Y/W/H, typography, binding, and table properties.

Validation errors are inline and non-blocking unless the model cannot safely apply the value.

## Data binding

Use one binding visual vocabulary:
- bound field: `DataBindingBadge` + technical path
- expression: same badge family with expression indicator
- repeating array: loop indicator + path
- missing field: error semantic icon/text and repair action
- invalid expression: inline error with location/context

Dragging a data field onto a valid canvas/table target shows a primary drop state; invalid targets show an error cue plus icon/message where feasible.

## Table editor

Selection context levels: table → column/row → cell → multi-cell.

Column resizing displays temporary width measurement in mm (or current physical unit) and does not mutate unrelated columns until commit semantics require it.

Repeating rows are distinguishable but restrained; never fill an entire row with saturated accent color.

Current Phase-2 table metadata (key, label, width, alignment, add/remove/edit/reorder, undo/redo) must remain functional during visual migration.

## Preview/output

PDF, system printer, and ESC/POS share one Preview workspace shell and common status/zoom/feedback primitives.

Output warnings should generally be non-blocking: printable overflow, unsupported duplex, rasterized image/logo, encoding/profile concern.

Blocking errors are reserved for inability to render or output safely.

## Feedback

- save/export success: short toast
- local field validation: inline
- printer state: inline alert within output panel
- destructive delete confirmation: dialog only when data-loss risk justifies interruption

Do not cover the canvas with full-screen progress for routine generation; preserve previous preview where possible.

## Accessibility

- critical states cannot rely on color alone
- tooltips for icon-only toolbar actions
- logical keyboard focus order follows the shell and active context
- compact controls must still provide practical desktop hit targets
- text contrast follows semantic token pairing
