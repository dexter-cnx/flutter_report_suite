
# flutter_offline_report - Production Package

Package สำหรับ Flutter Mobile ที่รับ template + data แล้วสร้าง PDF/พิมพ์ได้เลย Offline 100%

## Features
- Thermal 58/80mm auto height
- A4 with header/footer/page break
- PDF share
- Thai font support
- Printer module included

## Usage

```dart
import 'package:flutter_offline_report/flutter_offline_report.dart';

final printer = FlutterReportPrinter();

// 1. Load template (จาก assets หรือ Hive หรือ API)
final template = jsonDecode(await rootBundle.loadString('assets/templates/thermal_80.json'));

// 2. Data
final data = {"shop": {"name": "ร้านผม"}, "items": [...]};

// 3. Generate
final pdfBytes = await printer.generatePdf(templateJson: template, data: data);

// 4. Print / Preview / Share
await printer.preview(templateJson: template, data: data);
await printer.printDirect(templateJson: template, data: data);
await printer.sharePdf(templateJson: template, data: data, filename: 'receipt.pdf');

// List printers
final printers = await printer.listPrinters();
```

## Package Structure
```
lib/
  flutter_offline_report.dart (export)
  src/
    models/report_template.dart
    services/pdf_render_service.dart
    services/template_storage_service.dart
    printer/printer_service.dart
example/
  lib/main.dart - ตัวอย่างใช้งานครบ
```

## Example
cd example
flutter pub get
flutter run
```
