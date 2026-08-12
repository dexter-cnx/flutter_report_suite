# Google Stitch Raw Handoff Manifest

Source archive reviewed for this design handoff: `stitch_flutter_report_studio.zip`.

The downloaded Stitch archive contains the following generated artifacts:

```text
report_designer_workspace/{screen.png,code.html}
refined_report_designer_workspace/{screen.png,code.html}
report_designer_data_binding_workspace/{screen.png,code.html}
report_template_gallery/{screen.png,code.html}
report_designer_table_editor_workspace/{screen.png,code.html}
report_designer_preview_output_workspace/{screen.png,code.html}
report_designer_final_consolidated_workspace/{screen.png,code.html}
report_designer_unified_preview_output/{screen.png,code.html}
report_template_gallery_unified_style/{screen.png,code.html}
studio_precision_design_system_document.md
developer_handoff_studio_precision_spec.md
studio_precision_1/DESIGN.md
studio_precision_2/DESIGN.md
```

The generated HTML and screenshots are treated as visual/reference artifacts, not executable source for the Flutter application. They are intentionally not copied into the application source tree by this handoff commit.

## Normalization precedence

The Stitch generations conflict in a few token values. The normalized implementation source of truth is `../DESIGN_SYSTEM.md`, using this precedence:

1. `developer_handoff_studio_precision_spec.md`
2. `studio_precision_design_system_document.md`
3. `studio_precision_2/DESIGN.md`
4. `studio_precision_1/DESIGN.md` as historical/non-canonical reference

Key conflict decisions:

- toolbar: 56 px, not 48 px
- left panel: 264 px, not 280 px
- right inspector: 320 px
- primary accent: `#6366F1`, not `#4648D4`
- canvas selection: 1 px primary base outline with 2 px focus ring semantics
- selection handle: 8 px

## Engineering rule

Do not paste generated Stitch HTML/CSS into the Flutter codebase. Recreate the design through the semantic tokens and reusable Flutter components defined in the normalized handoff documents.
