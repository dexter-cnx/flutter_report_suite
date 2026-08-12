# Bundled Thai PDF fonts

Production PDF rendering expects these package assets:

- `NotoSansThai-Regular.ttf`
- `NotoSansThai-Bold.ttf`

Source family: Noto Sans Thai, maintained by the Noto Project Authors.
License: SIL Open Font License 1.1 (`OFL.txt`).

The engine resolves fonts through Flutter package asset keys first:

- `packages/report_engine/assets/fonts/NotoSansThai-Regular.ttf`
- `packages/report_engine/assets/fonts/NotoSansThai-Bold.ttf`

A legacy app-relative lookup is retained only for compatibility with host applications that previously bundled fonts themselves.

Do not replace the production font files with empty or synthetic placeholders. Rendering Thai with the Helvetica fallback is not a supported production configuration.
