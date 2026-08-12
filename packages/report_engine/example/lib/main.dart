import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:report_engine/report_engine.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'report_engine Example',
      debugShowCheckedModeBanner: false,
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
  final FlutterReportPrinter _printer = FlutterReportPrinter();
  final EscPosPrinterService _escPos = EscPosPrinterService();

  final Map<String, dynamic> _mockData = {
    'shop': {
      'name': 'ร้าน Dexter Coffee',
      'branch': 'นิมมาน',
      'tel': '081-xxx-xxxx',
    },
    'orderId': 'ORD-001',
    'date': '12/08/2026',
    'items': [
      {'name': 'ลาเต้', 'qty': 2, 'price': 65},
      {'name': 'ครัวซองต์', 'qty': 1, 'price': 85},
    ],
    'total': 215,
    'note': 'ขอบคุณครับ',
  };

  Map<String, dynamic> get _a4Data => {
        ..._mockData,
        'invoiceNo': 'INV-2026-001',
        'dueDate': '19/08/2026',
        'company': {
          'name': 'Dexter Report Solutions Co., Ltd.',
          'taxId': '0105566123456',
        },
        'customer': {
          'name': 'บริษัท ลูกค้าตัวอย่าง จำกัด',
          'address': 'เชียงใหม่ 50200',
        },
        'items': List<Map<String, dynamic>>.generate(
          30,
          (index) {
            final qty = (index % 4) + 1;
            final price = 25 + (index * 3);
            return {
              'no': index + 1,
              'name': 'รายการสินค้า ${index + 1}',
              'qty': qty,
              'price': price,
              'total': qty * price,
            };
          },
        ),
      };

  Future<Map<String, dynamic>> _loadTemplate(String name) async {
    final source = await rootBundle.loadString('assets/templates/$name');
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Template must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _preview(
    String templateFile,
    String title, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final template = await _loadTemplate(templateFile);
      final bytes = await _printer.generatePdf(
        templateJson: template,
        data: data ?? _mockData,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: PdfPreview(
              build: (_) async => bytes,
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        ),
      );
    } catch (error) {
      _showError('Unable to render template: $error');
    }
  }

  Future<void> _buildQuickEscPosReceipt({
    EscPosEncodingConfig? encodingConfig,
    String label = 'legacy',
  }) async {
    try {
      final bytes = await _escPos.buildQuickReceipt(
        data: _mockData,
        encodingConfig: encodingConfig,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ESC/POS $label receipt generated: ${bytes.length} bytes',
          ),
        ),
      );
    } catch (error) {
      _showError('Unable to generate ESC/POS receipt: $error');
    }
  }

  Future<void> _copyTemplateJson(String templateFile) async {
    try {
      final template = await _loadTemplate(templateFile);
      final json = const JsonEncoder.withIndent('  ').convert(template);
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template JSON copied to clipboard.')),
      );
    } catch (error) {
      _showError('Unable to export template JSON: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('report_engine Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Package usage',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: const SelectableText(
              "final printer = FlutterReportPrinter();\n"
              "final bytes = await printer.generatePdf(\n"
              "  templateJson: template,\n"
              "  data: data,\n"
              ");\n"
              "\n"
              "// ESC/POS Thai code-table numbers are printer-specific.\n"
              "const thai = EscPosEncodingConfig.cp874(\n"
              "  codeTable: printerSpecificCodeTable,\n"
              ");\n"
              "// Or avoid code-page dependency entirely:\n"
              "const rasterThai = EscPosEncodingConfig.raster();",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const Divider(height: 32),
          FilledButton(
            onPressed: () => _preview('thermal_80.json', 'Thermal 80 mm'),
            child: const Text('Thermal 80 mm receipt'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _preview('thermal_58.json', 'Thermal 58 mm'),
            child: const Text('Thermal 58 mm receipt'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _preview(
              'a4_invoice.json',
              'A4 invoice — 30 rows',
              data: _a4Data,
            ),
            child: const Text('A4 invoice with page breaking'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _preview('pdf_receipt.json', 'Thai PDF receipt'),
            child: const Text('Thai PDF preview / share'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _buildQuickEscPosReceipt(),
            child: const Text('Generate legacy ESC/POS quick receipt'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _buildQuickEscPosReceipt(
              encodingConfig: const EscPosEncodingConfig.raster(),
              label: 'Thai raster',
            ),
            child: const Text('Generate Thai raster ESC/POS receipt'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _copyTemplateJson('a4_invoice.json'),
            child: const Text('Export A4 template JSON to clipboard'),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Printer>>(
            future: _printer.listPrinters(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Looking for printers…');
              }
              if (snapshot.hasError) {
                return Text('Unable to list printers: ${snapshot.error}');
              }
              final printers = snapshot.data ?? const <Printer>[];
              final names = printers.map((printer) => printer.name).join(', ');
              return Text(
                printers.isEmpty
                    ? 'No system printers found.'
                    : 'Printers (${printers.length}): $names',
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Physical Thai ESC/POS output remains hardware-dependent. Configure a code-table number from the target printer manual or use raster fallback, then validate on the actual printer before claiming compatibility.',
          ),
        ],
      ),
    );
  }
}
