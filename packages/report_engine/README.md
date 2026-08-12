# report_engine

Offline-first Flutter report engine for rendering template JSON with runtime data to PDF/A4/thermal output, plus direct ESC/POS printing over Bluetooth.

## Public API

```dart
import 'package:report_engine/report_engine.dart';
```

The package exposes:

- `ReportTemplate`, `ReportElement`, and `PaperConfig`
- `ReportValueResolver`
- `PdfRenderService`
- `TemplateStorageService`
- `FlutterReportPrinter`
- `EscPosPrinterService`

## PDF / system printer flow

```dart
final printer = FlutterReportPrinter();

final bytes = await printer.generatePdf(
  templateJson: template,
  data: data,
);

await printer.preview(templateJson: template, data: data);
await printer.sharePdf(
  templateJson: template,
  data: data,
  filename: 'receipt.pdf',
);

final printers = await printer.listPrinters();
if (printers.isNotEmpty) {
  await printer.printDirect(
    printer: printers.first,
    templateJson: template,
    data: data,
  );
}
```

## Template storage

```dart
final storage = TemplateStorageService();
await storage.init();
await storage.saveTemplate('receipt', template);
final cached = await storage.getTemplate('receipt');
```

Templates are JSON-encoded in Hive so the engine remains offline-first and does not require generated Hive adapters.

## ESC/POS Bluetooth flow

```dart
final escPos = EscPosPrinterService();
final devices = await escPos.scanPrinters();

if (devices.isNotEmpty) {
  await escPos.printReceipt(
    device: devices.first.device,
    templateJson: template,
    data: data,
  );
}
```

Bluetooth permissions still need to be declared/configured by the host Android/iOS app according to the platform requirements.

## Template contract

```json
{
  "id": "receipt",
  "version": 1,
  "paper": {
    "type": "thermal",
    "widthMm": 80,
    "heightMm": 200,
    "autoHeight": true,
    "marginMm": 3
  },
  "elements": []
}
```

`text` elements treat `key` as literal text. Dynamic elements resolve paths such as `{{shop.name}}`. Table elements use `columns` to map list rows to printable cells.

## Tests

```bash
cd packages/report_engine
flutter pub get
flutter test
```
