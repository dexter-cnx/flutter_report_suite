# Flutter Report Suite Designer — Design System

Status: **Normalized implementation source of truth**

Source material: Google Stitch rounds 1–7 export (`stitch_flutter_report_studio.zip`) and the current `apps/designer` implementation on `main`.

## Decision rule

The Stitch export contains two partially conflicting token sets. For implementation, this document adopts the later developer-handoff/final-consolidated values as canonical. Earlier generated values are retained only as visual references.

Canonical precedence:

1. `developer_handoff_studio_precision_spec.md`
2. `studio_precision_design_system_document.md`
3. `studio_precision_2/DESIGN.md`
4. `studio_precision_1/DESIGN.md` (non-canonical historical variant)

Important normalized conflicts:

| Token | Canonical | Earlier variant | Decision |
|---|---:|---:|---|
| top toolbar | 56 px | 48 px | 56 px |
| left panel | 264 px | 280 px | 264 px |
| right inspector | 320 px | 280 px | 320 px |
| primary | `#6366F1` | `#4648D4` | `#6366F1` |
| selection outline | 1 px | 2 px | 1 px base; 2 px only for focus ring |
| selection handle | 8 px | 6 px | 8 px |

## Product character

The Designer is a desktop-first professional authoring tool: precise, compact, calm, and content-first. The visual language should feel closer to Figma/Framer/Linear-class productivity software than to a generic Material dashboard.

Avoid oversized cards, large mobile controls, decorative gradients, pervasive glassmorphism, heavy elevation, and page-specific one-off styling.

## Color tokens

| Flutter token | Hex | Usage |
|---|---|---|
| `appBackground` | `#F9FAFB` | app shell / inactive chrome |
| `panelBackground` | `#FFFFFF` | left panel, inspector, toolbar surfaces |
| `workspaceBackground` | `#E5E7EB` | canvas and preview workspace |
| `canvasBackground` | `#FFFFFF` | printable page |
| `surfaceHover` | `#F3F4F6` | row/button hover |
| `surfaceSelected` | `#EEF2FF` | selected rows / subtle active state |
| `borderDefault` | `#E5E7EB` | 1 px structural dividers |
| `borderStrong` | `#D1D5DB` | active boundaries |
| `textPrimary` | `#111827` | headings / main values |
| `textSecondary` | `#4B5563` | labels / metadata |
| `textMuted` | `#9CA3AF` | placeholder / disabled secondary text |
| `primary` | `#6366F1` | selected, focused, primary action |
| `primaryHover` | `#4F46E5` | primary hover |
| `primarySubtle` | `#EEF2FF` | accent tint |
| `success` | `#10B981` | valid/success |
| `warning` | `#F59E0B` | warnings |
| `error` | `#EF4444` | errors |

Future dark mode must be implemented by semantic token substitution rather than hard-coded widget colors.

## Typography

Preferred UI families: **Inter** for general UI and **Geist** for app-title/technical accents when bundled and licensing/tooling are confirmed. Do not introduce runtime web-font fetching; the Designer remains offline-first.

| Role | Size | Weight | Line height |
|---|---:|---:|---:|
| appTitle | 16 | 600 | 24 |
| screenTitle | 18 | 600 | 28 |
| panelTitle | 13 | 600 | 20 |
| sectionTitle | 11 | 600 | 16 |
| controlLabel | 12 | 500 | 16 |
| controlValue | 13 | 400 | 20 |
| body | 13 | 400 | 20 |
| helper | 11–12 | 400 | 16 |
| status | 11 | 400 | 16 |
| monospace | 12 | 400 | 18 |

`sectionTitle` may use uppercase with restrained letter spacing. Monospace is for expressions, data paths, dimensions, coordinates, and diagnostics, not normal prose.

## Spacing

Use a 4 px base rhythm, with the normalized scale:

`2, 4, 8, 12, 16, 20, 24, 32, 40`

Recommended aliases: `xxs=2`, `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=20`, `xxl=24`, `xxxl=32`, `huge=40`.

Do not add arbitrary spacing values unless required by platform hit-testing or printable geometry.

## Radius

- badge/small indicator: 4 px
- control/button/input: 6 px
- menu/popover: 8 px
- floating surface: 10 px when necessary
- dialog: 12 px
- structural panels: 0 px

Printable report elements default to square edges unless their report style explicitly specifies radius.

## Layout dimensions

Canonical desktop baseline:

- top toolbar: **56 px**
- bottom status bar: **32 px**
- left tool/navigation panel: **264 px**
- right inspector: **320 px**
- panel header: **32 px**
- compact control: **28 px**
- standard control: **32 px**
- tree/layer row: **28–30 px**
- menu row: **28–32 px**

Responsive behavior:

- `>= 1440`: full shell
- `1280–1439`: slightly compress side panels where necessary
- `1024–1279`: left panel becomes collapsible; canvas keeps priority
- `< 1024`: one or both secondary panels become drawers/overlays; do not shrink the printable workspace into a phone-style form

The existing `>900` breakpoint in `DesignerPage` is implementation debt and should be migrated to this policy.

## Elevation

- structural panels: none
- canvas paper: subtle physical separation, approximately `0 2 8 rgba(0,0,0,.05)`
- menus/popovers: subtle `0 4 12 rgba(0,0,0,.08)` class shadow
- contextual toolbar: low elevation
- dialog: moderate elevation + dimmed backdrop
- selection: no shadow

## Interaction tokens

- hover: `surfaceHover`
- selected row: `primarySubtle` + optional 2 px left accent indicator
- canvas selection: 1 px `primary`
- handles: 8×8, primary border/fill treatment with white contrast
- focus: 2 px primary focus ring
- drag source: ~70% opacity / slight elevation
- valid drop: primary insertion line or subtle primary tint
- invalid drop: error indicator; never rely on color alone

## Flutter token structure

Implementation should introduce semantic tokens rather than hard-coded colors inside page widgets:

```text
lib/design_system/
├── designer_theme.dart
├── designer_colors.dart
├── designer_typography.dart
├── designer_spacing.dart
├── designer_radius.dart
├── designer_layout.dart
└── designer_elevation.dart
```

Recommended public types: `DesignerColors`, `DesignerTypography`, `DesignerSpacing`, `DesignerRadius`, `DesignerLayout`, `DesignerElevation`, `DesignerTheme`.

`ThemeData` remains the Flutter integration point, but design-tool-specific values should be exposed through dedicated constants/ThemeExtensions instead of repeated `Colors.grey.shade...` expressions.
