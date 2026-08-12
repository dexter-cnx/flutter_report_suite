# Phase 3 Sunmi Adapter Audit

Date: 2026-08-12

## Decision

Keep Sunmi integration outside the cross-platform `report_engine` core in an optional companion package:

```text
packages/report_engine_sunmi/
```

The companion package depends on `report_engine` and `sunmi_printer_plus`, while `report_engine` itself remains free of the Android-only Sunmi plugin.

## Dependency reviewed

- package: `sunmi_printer_plus`
- version reviewed: `4.1.1`
- upstream repository: `brasizza/sunmi_printer`
- license: BSD-3-Clause

## Compatibility findings

### Platform

`sunmi_printer_plus` 4.1.1 declares only an Android plugin implementation. It must not become a mandatory dependency of the cross-platform core.

### Dart / Flutter

Upstream 4.1.1 declares:

```text
Dart >= 3.5.3 < 4.0.0
Flutter >= 1.20.0
```

The project reference toolchain Flutter 3.32.7 satisfies this Dart requirement.

### Android

The upstream 4.x Android configuration declares:

```text
compileSdk 34
minSdk 21
AGP 8.1.4
Kotlin 1.8.22
Java 8 target
```

Native dependencies include:

```text
com.sunmi:printerlibrary:1.0.23
com.sunmi:printerx:1.0.17
```

### API surface used

The adapter uses current non-deprecated APIs where available:

- `printEscPos(List<int>)`
- `cutPaper()`
- `openDrawer()`
- `isDrawerOpen()`
- `getId()`
- `getType()`
- `getVersion()`
- `rebindPrinter()`

`rebindPrinter()` is exposed for recovery when the Android printer service is unavailable or has been killed.

## Architecture impact

`SunmiPrinterAdapter` implements core contracts only:

```text
EscPosTransport
PrinterDiscoverySource
```

Plugin-specific objects do not cross into the `report_engine` public printer model. Sunmi discovery returns `UnifiedPrinter` with connection type `embedded`.

The companion package can be supplied to unified discovery as an additional source:

```dart
final sunmi = SunmiPrinterAdapter();
final discovery = PrinterDiscoveryService.standard(
  additionalSources: <PrinterDiscoverySource>[sunmi],
);
```

## Web / Desktop impact

The Android-only dependency is isolated in `report_engine_sunmi`; Web/Desktop/iOS consumers of `report_engine` do not need to resolve or import the Sunmi adapter package.

The core package must continue to pass its existing Web/Desktop/native build gates independently of `report_engine_sunmi`.

## Publication impact

The companion package currently uses a monorepo path dependency on `report_engine` and is marked `publish_to: none`. Before any future pub.dev publication:

1. publish or otherwise version the core package first,
2. replace the path dependency with a compatible hosted version constraint,
3. review Android-only package metadata and supported platform declaration,
4. run `dart pub publish --dry-run` / `flutter pub publish --dry-run` as appropriate.

## Validation still required

Automated/local:

- `report_engine`: pub get, format, analyze, test
- `report_engine/example`: analyze and Android debug build
- `report_engine_sunmi`: pub get, format, analyze, test
- Android compile consuming `report_engine_sunmi`

Physical hardware:

- raw ESC/POS printing on an available Sunmi model
- Thai strategy selected for that model
- paper cut where supported
- cash drawer where attached/supported
- service rebind recovery where practical

No specific Sunmi model compatibility should be claimed until physical validation is recorded.
