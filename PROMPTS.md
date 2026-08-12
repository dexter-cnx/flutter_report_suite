
# PROMPTS - Complete Suite

## Prompt 1: Create Monorepo Package (report_engine)

```
Create Flutter package `report_engine` in packages/report_engine.

Requirements:
- pubspec: pdf, printing, hive_flutter, barcode_widget, esc_pos_utils_plus, flutter_blue_plus, permission_handler
- Structure:
  lib/report_engine.dart exports:
    src/models/report_template.dart (PaperConfig with type,widthMm,heightMm,autoHeight,marginMm, ReportElement with id,type,key,x,y,w,h,style,columns, ReportTemplate)
    src/services/pdf_render_service.dart: class PdfRenderService with render(templateJson, data) -> Uint8List. Must support thermal (PdfPageFormat width * mm, double.infinity) and A4 (MultiPage with header/footer, Table.fromTextArray). Thai font THSarabunNew.ttf loading with fallback. Resolve {{shop.name}} nested keys.
    src/services/template_storage_service.dart: Hive storage for offline templates
    src/printer/printer_service.dart: class FlutterReportPrinter with generatePdf, preview, printDirect, sharePdf, listPrinters (using printing package)
    src/printer/esc_pos_printer_service.dart: class EscPosPrinterService with scanPrinters() using flutter_blue_plus, printReceipt(device, templateJson, data, paperSize) converting template elements to ESC/POS bytes via esc_pos_utils_plus Generator, chunk write 180 bytes, buildQuickReceipt(data) helper.

- assets/templates: thermal_80.json, thermal_58.json, a4_invoice.json, pdf_receipt.json with elements array

Production quality, offline 100%
```

## Prompt 2: Create Designer App (Web/Desktop/Mobile)

```
Create Flutter app `report_designer` in apps/designer that depends on report_engine via path ../../packages/report_engine.

Requirements:
- Must work on Web, Desktop (Windows/macOS/Linux), Mobile (Android/iOS) - responsive layout
- pubspec: report_engine path, printing, uuid, file_picker
- lib/pages/designer_page.dart:
  - State: paperType (thermal/a4/pdf), widthMm, heightMm, autoHeight, List<Map> elements, selectedId
  - Top AppBar: Paper type dropdown, Preview PDF button (uses FlutterReportPrinter.generatePdf), Export JSON button (show JsonEncoder with indent)
  - Left Panel (180px on wide): Add buttons: Text, Dynamic {{field}}, Line, Table {{items}}, QR Code, Barcode. Paper slider widthMm 48-210, Switch autoHeight
  - Center Canvas: Container width = widthMm * 3 px scale, height = autoHeight ? 600 : heightMm*2.5, white background, Stack of Positioned draggable elements via GestureDetector onPanUpdate. Show border blue if selected. Preview rendering: text, line as Divider, qrcode as icon, table as placeholder.
  - Right Panel (280px): Properties of selected element: TextField for key, TextFields for x,y,w,h with onSubmitted, Slider fontSize 6-30, Checkbox bold, Dropdown align left/center/right, Delete button
  - Responsive: if width > 900 use Row [left, canvas, right], else Column [canvasExpanded, bottom Row left+right]
  - mockData for preview: shop, items, total etc.
  - templateJson getter returns {id, version, paper:{type,widthMm,heightMm,autoHeight,marginMm}, elements}

- lib/main.dart: MaterialApp with DesignerPage

- Production polish: useMaterial3, debugShowCheckedModeBanner false

Deliver complete code.
```

## Prompt 3: Combine as Monorepo

```
Combine both into monorepo flutter_report_suite with:
- packages/report_engine
- apps/designer
- Root README.md explaining flow: Designer -> Export JSON -> Mobile loads JSON + data -> report_engine prints

Ensure designer uses report_engine package for PDF preview, so template JSON is always compatible.

Provide zip and instructions.
```
