# Continuous Integration

The repository uses GitHub Actions via `.github/workflows/ci.yml`.

## Runtime

CI is pinned to Flutter `3.32.7` so pull requests are checked with a repeatable SDK instead of whatever happens to be the latest stable release.

The workflow runs on:

- pull requests targeting `main`
- pushes to `main`
- manual `workflow_dispatch`

Concurrent runs for the same ref are cancelled when a newer commit is pushed.

## Quality jobs

### `report-engine`

Working directory: `packages/report_engine`

```bash
flutter pub get
flutter analyze
flutter test --coverage --reporter expanded
```

Coverage includes template parsing/serialization, nested value resolution, PDF rendering, and printer facade delegation.

### `designer-quality`

Working directory: `apps/designer`

```bash
flutter pub get
flutter analyze
flutter test --coverage --reporter expanded
```

The widget suite covers Designer startup, authoring controls, element creation/selection, table defaults, and JSON export behavior. Tests pin a desktop-sized viewport so responsive layout does not make interactions flaky on headless CI.

## Platform build jobs

The Designer contains Flutter-generated platform scaffolding for all supported targets:

- Android
- iOS
- Web
- macOS
- Windows
- Linux

CI performs compile-level smoke validation on every target:

| Job | Runner | Command |
| --- | --- | --- |
| `web-build` | Ubuntu | `flutter build web --release` |
| `android-build` | Ubuntu + JDK 17 | `flutter build apk --debug` |
| `linux-build` | Ubuntu | `flutter build linux --release` |
| `windows-build` | Windows | `flutter build windows --release` |
| `apple-builds` | macOS | `flutter build macos --release` and `flutter build ios --simulator --debug` |

The iOS job builds for the simulator and does not require code signing.

## Local equivalent

From repository root:

```bash
cd packages/report_engine
flutter pub get
flutter analyze
flutter test --coverage --reporter expanded

cd ../../apps/designer
flutter pub get
flutter analyze
flutter test --coverage --reporter expanded
flutter build web --release
```

Run native builds on their host operating system when practical:

```bash
flutter build apk --debug
flutter build linux --release
flutter build windows --release
flutter build macos --release
flutter build ios --simulator --debug
```

## Platform scaffolding policy

`apps/designer/android`, `ios`, `web`, `macos`, `windows`, and `linux` were generated with Flutter `3.32.7` using `flutter create`. Application-owned source (`lib/`), assets, and the existing `pubspec.yaml` remain the source of truth.

When upgrading Flutter substantially, regenerate or migrate platform files using Flutter tooling rather than hand-editing generated build-system files unless a platform-specific customization requires it.

## Future quality gates

Useful next additions are:

1. Golden tests for canvas and property-panel layouts.
2. Integration tests for import/export round trips.
3. Printer adapter contract tests with mocked BLE/system-printer boundaries.
4. Coverage reporting/upload once a repository-wide threshold is agreed.
