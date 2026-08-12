# Changelog

## 1.0.0

Initial production release of `report_engine`.

### Rendering

- Shared JSON report-template contract for Designer and runtime rendering.
- A4, thermal 80mm, thermal 58mm, and custom paper PDF output.
- Multi-page table rendering with stable pagination behavior.
- Bundled Noto Sans Thai regular/bold fonts with package-aware asset loading.
- Thai, English, numeric, QR code, and barcode rendering.

### ESC/POS

- Transport-independent ESC/POS rendering.
- Configurable TIS-620 and CP874 output with explicit printer code-table selection.
- Rasterized Thai fallback using bundled Thai fonts.
- Quick-receipt 8/2/2 item, quantity, and price column semantics.
- Bluetooth Low Energy transport support through `flutter_blue_plus`.

### Printer architecture

- Unified printer discovery model with deterministic ordering and source isolation.
- System-printer and BLE discovery sources.
- Explicit cutter and cash-drawer capability contracts.
- Hardware operations remain separate from PDF and ESC/POS rendering.

### Offline storage

- Hive-backed local template storage.
- Save, load, rename, duplicate, delete, and JSON-compatible persistence flows.

### Validation

- Automated PDF geometry and pagination regression coverage.
- Thai PDF and ESC/POS software tests.
- Multi-platform Designer CI coverage remains separate from physical printer verification.

Physical printer compatibility is documented separately and must not be inferred from software-only tests.
