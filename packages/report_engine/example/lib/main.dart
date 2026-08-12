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

  Future<Map<String, dynamic>> _loadTemplate(String name) async {
    final source = await rootBundle.loadString('assets/templates/$name');
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Template must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _preview(String templateFile, String title) async {
    try {
      final template = await _loadTemplate(templateFile);
      final bytes = await _printer.generatePdf(
        templateJson: template,
        data: _mockData,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to render template: $error')),
      );
    }
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
              "await printer.sharePdf(\n"
              "  templateJson: template,\n"
              "  data: data,\n"
              ");",
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
            onPressed: () => _preview('a4_invoice.json', 'A4 invoice'),
            child: const Text('A4 invoice'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _preview('pdf_receipt.json', 'PDF receipt'),
            child: const Text('PDF receipt'),
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
        ],
      ),
    );
  }
}
