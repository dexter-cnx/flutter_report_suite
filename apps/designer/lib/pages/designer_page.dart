
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:report_engine/report_engine.dart';

class DesignerPage extends StatefulWidget {
  const DesignerPage({super.key});
  @override
  State<DesignerPage> createState() => _DesignerPageState();
}

class _DesignerPageState extends State<DesignerPage> {
  // Production state
  String paperType = 'thermal';
  double widthMm = 80;
  double heightMm = 200;
  bool autoHeight = true;
  List<Map<String, dynamic>> elements = [];
  String? selectedId;
  final _renderer = FlutterReportPrinter();

  Map<String, dynamic> mockData = {
    "shop": {"name": "ร้าน Dexter Coffee", "branch": "นิมมาน"},
    "orderId": "ORD-001",
    "date": "12/08/2026",
    "customer": {"name": "คุณสมชาย"},
    "items": [
      {"name": "ลาเต้ร้อน", "qty": 2, "price": 65},
      {"name": "ครัวซองต์", "qty": 1, "price": 85},
    ],
    "total": 215,
    "note": "ขอบคุณครับ"
  };

  void _addElement(String type) {
    final id = const Uuid().v4();
    setState(() {
      elements.add({
        "id": id,
        "type": type,
        "key": type == 'text' ? 'ข้อความตัวอย่าง' : '{{shop.name}}',
        "x": 10, "y": elements.length * 20.0,
        "w": type == 'line' ? widthMm - 10 : 60,
        "h": type == 'qrcode' ? 30 : 8,
        "style": {"fontSize": type == 'text' ? 12 : 10, "bold": false, "align": "left"}
      });
      selectedId = id;
    });
  }

  Map<String, dynamic> get templateJson => {
    "id": "custom_template",
    "version": 1,
    "paper": {"type": paperType, "widthMm": widthMm, "heightMm": heightMm, "autoHeight": autoHeight, "marginMm": 3},
    "elements": elements
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Designer - Thermal / A4 / PDF'),
        actions: [
          DropdownButton<String>(
            value: paperType,
            items: const [
              DropdownMenuItem(value: 'thermal', child: Text('Thermal')),
              DropdownMenuItem(value: 'a4', child: Text('A4')),
              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
            ],
            onChanged: (v) => setState(() {
              paperType = v!;
              if (v == 'thermal') { widthMm = 80; autoHeight = true; }
              else if (v == 'a4') { widthMm = 210; heightMm = 297; autoHeight = false; }
              else { widthMm = 80; heightMm = 200; autoHeight = true; }
            }),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Preview PDF', onPressed: () async {
            final pdf = await _renderer.generatePdf(templateJson: templateJson, data: mockData);
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Preview')), body: PdfPreview(build: (_) async => pdf))));
          }),
          IconButton(icon: const Icon(Icons.code), tooltip: 'Export JSON', onPressed: () {
            showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Template JSON'), content: SingleChildScrollView(child: SelectableText(const JsonEncoder.withIndent('  ').convert(templateJson))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
          }),
        ],
      ),
      body: isWide ? Row(children: [ _leftPanel(), _canvas(), _rightPanel() ]) : Column(children: [ _canvasExpanded(), _bottomPanels() ]),
    );
  }

  Widget _leftPanel() => Container(width: 180, color: Colors.grey[100], child: ListView(
    children: [
      const ListTile(title: Text('Add Element', style: TextStyle(fontWeight: FontWeight.bold))),
      _btn('Text', Icons.text_fields, () => _addElement('text')),
      _btn('Dynamic {{field}}', Icons.code, () => _addElement('dynamic_text')),
      _btn('Line', Icons.horizontal_rule, () => _addElement('line')),
      _btn('Table {{items}}', Icons.table_chart, () => _addElement('table')),
      _btn('QR Code', Icons.qr_code, () => _addElement('qrcode')),
      _btn('Barcode', Icons.barcode_reader, () => _addElement('barcode')),
      const Divider(),
      ListTile(title: Text('Paper: \${widthMm}mm', style: const TextStyle(fontSize: 12))),
      Slider(value: widthMm, min: 48, max: 210, divisions: 10, label: '\${widthMm}mm', onChanged: (v) => setState(() => widthMm = v)),
      SwitchListTile(title: const Text('Auto Height', style: TextStyle(fontSize: 12)), value: autoHeight, onChanged: (v) => setState(() => autoHeight = v)),
    ],
  ));

  Widget _btn(String label, IconData icon, VoidCallback onTap) => ListTile(leading: Icon(icon, size: 18), title: Text(label, style: const TextStyle(fontSize: 12)), onTap: onTap);

  Widget _canvas() => Expanded(flex: 3, child: _canvasContent());
  Widget _canvasExpanded() => Expanded(child: _canvasContent());

  Widget _canvasContent() => Container(
    color: Colors.grey[300],
    child: Center(
      child: Container(
        width: widthMm * 3, // visual scale 3px per mm
        height: autoHeight ? 600 : heightMm * 2.5,
        color: Colors.white,
        child: Stack(
          children: elements.map((el) {
            final isSelected = el['id'] == selectedId;
            return Positioned(
              left: (el['x'] as num).toDouble() * 3,
              top: (el['y'] as num).toDouble() * 3,
              child: GestureDetector(
                onTap: () => setState(() => selectedId = el['id']),
                onPanUpdate: (d) => setState(() {
                  el['x'] = ((el['x'] as num) + d.delta.dx / 3).clamp(0, widthMm).toDouble();
                  el['y'] = ((el['y'] as num) + d.delta.dy / 3).clamp(0, 1000).toDouble();
                }),
                child: Container(
                  width: (el['w'] as num).toDouble() * 3,
                  height: (el['h'] as num).toDouble() * 3,
                  decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 2 : 0.5), color: isSelected ? Colors.blue.withOpacity(0.1) : null),
                  child: _renderElementPreview(el),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );

  Widget _renderElementPreview(Map<String, dynamic> el) {
    final type = el['type'];
    final key = el['key'] ?? '';
    if (type == 'line') return Container(height: 1, color: Colors.black);
    if (type == 'qrcode') return const Icon(Icons.qr_code, size: 24);
    if (type == 'barcode') return Container(color: Colors.black, height: 8, margin: const EdgeInsets.all(4));
    if (type == 'table') return Container(color: Colors.grey[200], child: const Center(child: Text('TABLE {{items}}', style: TextStyle(fontSize: 8))));
    return Text(key.toString(), style: TextStyle(fontSize: ((el['style']?['fontSize'] ?? 10).toDouble() * 0.8, fontWeight: el['style']?['bold'] == true ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis);
  }

  Widget _rightPanel() {
    final selected = elements.where((e) => e['id'] == selectedId).firstOrNull;
    if (selected == null) return Container(width: 260, color: Colors.grey[50], child: const Center(child: Text('เลือก Element เพื่อแก้ไข')));
    return Container(
      width: 280, color: Colors.grey[50],
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          const Text('Properties', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Key / Text ({{shop.name}} or ธรรมดา)'), controller: TextEditingController(text: selected['key'])..selection = TextSelection.fromPosition(TextPosition(offset: selected['key'].toString().length)), onSubmitted: (v) => setState(() => selected['key'] = v)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'X'), keyboardType: TextInputType.number, controller: TextEditingController(text: selected['x'].toString()), onSubmitted: (v) => setState(() => selected['x'] = double.tryParse(v) ?? 0))),
            const SizedBox(width: 8),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Y'), keyboardType: TextInputType.number, controller: TextEditingController(text: selected['y'].toString()), onSubmitted: (v) => setState(() => selected['y'] = double.tryParse(v) ?? 0))),
          ]),
          Row(children: [
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'W'), keyboardType: TextInputType.number, controller: TextEditingController(text: selected['w'].toString()), onSubmitted: (v) => setState(() => selected['w'] = double.tryParse(v) ?? 10))),
            const SizedBox(width: 8),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'H'), keyboardType: TextInputType.number, controller: TextEditingController(text: selected['h'].toString()), onSubmitted: (v) => setState(() => selected['h'] = double.tryParse(v) ?? 10))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Font Size'),
            Expanded(child: Slider(value: (selected['style']?['fontSize'] ?? 10).toDouble(), min: 6, max: 30, onChanged: (v) => setState(() => selected['style']['fontSize'] = v))),
            Text('\${(selected['style']?['fontSize'] ?? 10).toInt()}'),
          ]),
          CheckboxListTile(title: const Text('Bold'), value: selected['style']?['bold'] == true, onChanged: (v) => setState(() => selected['style']['bold'] = v)),
          DropdownButton<String>(value: selected['style']?['align'] ?? 'left', items: const [DropdownMenuItem(value: 'left', child: Text('Left')), DropdownMenuItem(value: 'center', child: Text('Center')), DropdownMenuItem(value: 'right', child: Text('Right'))], onChanged: (v) => setState(() => selected['style']['align'] = v)),
          const SizedBox(height: 12),
          ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text('ลบ Element'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => setState(() { elements.removeWhere((e) => e['id'] == selectedId); selectedId = null; })),
        ],
      ),
    );
  }

  Widget _bottomPanels() => SizedBox(height: 200, child: Row(children: [Expanded(child: _leftPanel()), Expanded(child: _rightPanel())]));
}
