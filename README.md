
# Flutter Report Suite - Monorepo Production

Structure:
```
flutter_report_suite/
  packages/
    report_engine/  -> Flutter package (thermal 58/80, A4, PDF, ESC/POS)
      lib/src/
        models/report_template.dart
        services/pdf_render_service.dart
        services/template_storage_service.dart
        printer/printer_service.dart (PDF)
        printer/esc_pos_printer_service.dart (Bluetooth ESC/POS direct)
  apps/
    designer/ -> Designer App (Web/Desktop/Mobile)
      lib/pages/designer_page.dart - Drag & Drop canvas, 3 paper types

  PROMPTS.md - prompts for AI generation
```

## Quick Start

### 1. Package
cd packages/report_engine
flutter pub get

### 2. Designer (Web/Desktop/Mobile support)
cd apps/designer
flutter pub get
flutter run -d chrome  # Web
flutter run -d windows # Desktop
flutter run -d android # Mobile

Designer features:
- Add Text, Dynamic {{field}}, Line, Table, QR, Barcode
- Drag & Drop on canvas
- Paper switch: Thermal 58/80, A4, PDF
- Properties panel: x,y,w,h,fontSize,bold,align
- Preview PDF instantly
- Export JSON (compatible with report_engine)

### Flow
Designer (Web) -> Export template.json -> Save to server/Hive -> Mobile app loads json + data -> report_engine renders -> Print/Share
