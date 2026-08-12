# Continuous Integration

The repository uses GitHub Actions via `.github/workflows/ci.yml`.

## Runtime

CI is pinned to Flutter `3.32.7` so pull requests are checked with a repeatable SDK instead of whatever happens to be the latest stable release.

The workflow runs on:

- pull requests targeting `main`
- pushes to `main`
- manual `workflow_dispatch`

Concurrent runs for the same ref are cancelled when a newer commit is pushed.

## Jobs

### `report-engine`

Working directory: `packages/report_engine`

Checks:

```bash
flutter pub get
flutter analyze
flutter test --reporter expanded
```

This is the main quality gate because `report_engine` contains the reusable template model, resolver, PDF renderer, storage layer, printer facade, and ESC/POS implementation.

### `designer`

Working directory: `apps/designer`

Checks:

```bash
flutter pub get
flutter analyze
```

The Designer currently contains source and assets but does not yet include generated Flutter platform folders such as `web/`, `android/`, `ios/`, `macos/`, `windows/`, and `linux/`. For that reason CI intentionally does not run `flutter build web` or platform builds yet. A build job should be added after the application receives normal Flutter platform scaffolding.

## Local equivalent

From repository root:

```bash
cd packages/report_engine
flutter pub get
flutter analyze
flutter test --reporter expanded

cd ../../apps/designer
flutter pub get
flutter analyze
```

## Recommended next CI stages

After platform scaffolding and Designer tests are added, extend CI with:

1. Designer widget tests.
2. `flutter build web --release` smoke build.
3. Android debug APK build.
4. Package coverage upload.
5. Optional golden tests for Designer canvas rendering.

Do not add platform build gates before the corresponding platform directories and platform-specific plugin configuration exist; otherwise CI failures will reflect incomplete project scaffolding rather than application regressions.
