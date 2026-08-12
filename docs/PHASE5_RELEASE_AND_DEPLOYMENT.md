# Phase 5 — Release and GitHub Pages Deployment

Phase 5 closes the software release path for `report_engine` and deploys the Designer as a static Flutter Web application.

## Task 16 — `report_engine` pub.dev readiness

Release target: `report_engine` 1.0.0.

The package publication boundary is intentionally limited to core for the first release:

- `report_engine` — publish-ready for pub.dev after CI dry-run passes.
- `report_engine_sunmi` — remains unpublished at 0.1.0 for now.

`report_engine_sunmi` stays unpublished because it is Android/hardware-specific, still depends on core through a monorepo path dependency, and physical Sunmi compatibility remains unverified.

Required core release artifacts:

- package metadata (`repository`, `issue_tracker`, topics)
- package-level MIT `LICENSE`
- `CHANGELOG.md`
- pub.dev-oriented package README
- format/analyze/test gates
- `flutter pub publish --dry-run`

The CI dry-run is a release-readiness gate only. Actual publication requires an explicit maintainer release action and pub.dev credentials.

## Task 17 — Designer GitHub Pages

The Designer is backend-free and is deployed as a Flutter Web project site.

Expected project-site URL:

```text
https://dexter-cnx.github.io/flutter_report_suite/
```

The workflow lives at:

```text
.github/workflows/pages.yml
```

It builds with:

```bash
cd apps/designer
flutter pub get
flutter build web --release --base-href /flutter_report_suite/
```

The current Designer uses `MaterialApp(home: ...)` and does not expose path-based deep-link routes, so GitHub Pages does not require a SPA rewrite or custom `404.html` fallback for the current navigation model.

### One-time repository setting

Before the first production deployment, configure GitHub Pages to use **GitHub Actions** as the publishing source in repository Settings → Pages. The normal workflow `GITHUB_TOKEN` cannot enable Pages automatically; the workflow only builds and deploys after Pages is enabled.

### Deployment workflow

On pushes to `main` that affect Designer/core web inputs:

```text
checkout
  ↓
Flutter 3.32.7
  ↓
configure Pages
  ↓
flutter build web --release --base-href /flutter_report_suite/
  ↓
upload Pages artifact
  ↓
deploy to github-pages environment
```

The deployment workflow is deliberately separate from `.github/workflows/ci.yml`:

- CI proves a commit is acceptable.
- Pages deploys an accepted `main` commit.

### Post-deployment smoke test

After the first successful deployment, verify on the live Pages origin:

- root URL loads without 404s
- Flutter JS/WASM/assets resolve below `/flutter_report_suite/`
- bundled templates load
- Noto Sans Thai assets load
- template gallery opens
- Designer editing works
- browser-local persistence works after reload
- JSON import/export works
- PDF preview/generation works
- Thai PDF generation works
- desktop and mobile browser layouts remain usable

Do not use GitHub Pages deployment as evidence for physical ESC/POS, BLE, cutter, cash-drawer, or Sunmi compatibility.

## Release closure

Before v1.0.0 is declared production-ready:

1. Phase 5 PR CI must pass, including pub.dev dry-run.
2. Merge the Phase 5 PR into `main`.
3. Enable GitHub Pages with GitHub Actions as source if not already enabled.
4. Verify the first Pages deployment and live smoke test.
5. Update `docs/PROJECT_HANDOFF.md` with the final run/deployment evidence.
6. Create the v1.0.0 tag/GitHub Release.
7. Publish `report_engine` only through an explicit maintainer action.

Physical printer evidence remains a separate hardware release record and must not be inferred from the software release gates.
