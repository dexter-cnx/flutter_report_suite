
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline_report/flutter_offline_report.dart';
import 'package:printing/printing.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Package Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});
  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  final _printer = FlutterReportPrinter();

  Map<String, dynamic> mockData = {
    "shop": {"name": "ร้าน Dexter Coffee", "branch": "นิมมาน", "tel": "081-xxx-xxxx"},
    "orderId": "ORD-001",
    "date": "12/08/2026",
    "items": [
      {"name": "ลาเต้", "qty": 2, "price": 65},
      {"name": "ครัวซองต์", "qty": 1, "price": 85},
    ],
    "total": 215,
    "note": "ขอบคุณครับ"
  };

  Future<Map<String, dynamic>> loadTemplate(String name) async {
    final str = await rootBundle.loadString('assets/templates/\$name');
    return jsonDecode(str);
  }

  Future<void> doPrint(String templateFile, String title) async {
    final tpl = await loadTemplate(templateFile);
    final pdf = await _printer.generatePdf(templateJson: tpl, data: mockData);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(build: (_) async => pdf, allowPrinting: true, allowSharing: true),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_offline_report Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('PACKAGE USAGE:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: const Text(
              "final printer = FlutterReportPrinter();\n"
              "final pdf = await printer.generatePdf(templateJson: template, data: data);\n"
              "await printer.printDirect(templateJson: template, data: data);\n"
              "await printer.sharePdf(templateJson: template, data: data);",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const Divider(height: 32),
          ElevatedButton(onPressed: () => doPrint('thermal_80.json', 'Thermal 80mm'), child: const Text('Thermal 80mm - ใบเสร็จ')),
          ElevatedButton(onPressed: () => doPrint('thermal_58.json', 'Thermal 58mm'), child: const Text('Thermal 58mm - ใบเสร็จเล็ก')),
          ElevatedButton(onPressed: () => doPrint('a4_invoice.json', 'A4'), child: const Text('A4 - ใบแจ้งหนี้ (ทดสอบตัดหน้า)')),
          ElevatedButton(onPressed: () => doPrint('pdf_receipt.json', 'PDF'), child: const Text('PDF - แชร์ไลน์')),
          const SizedBox(height: 24),
          
          const Divider(height: 32),
          const Text('4. ESC/POS Direct (Bluetooth) - เร็ว x3', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              // Example usage:
              // final esc = EscPosPrinterService();
              // final devices = await esc.scanPrinters();
              // await esc.printReceipt(device: devices.first.device, templateJson: tpl, data: mockData);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ดูโค้ดตัวอย่างใน EscPosPrinterService - เชื่อมต่อ Bluetooth แล้วพิมพ์ได้เลย')));
            },
            child: const Text('Scan & Print ESC/POS (ดูโค้ด)'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: const Text('EscPosPrinterService().printReceipt() = พิมพ์ตรง ไม่ผ่าน PDF เร็วมากสำหรับ XP-58/80, Sunmi', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: _printer.listPrinters(),
            builder: (c, snap) {
              if (!snap.hasData) return const Text('กำลังหา printer...');
              return Text('พบ Printer: \${snap.data!.length} เครื่อง\n\${snap.data!.map((p) => p.name).join(", ")}');
            },
          )
        ],
      ),
    );
  }
}
