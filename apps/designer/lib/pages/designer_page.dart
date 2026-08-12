import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:report_engine/report_engine.dart';
import 'package:uuid/uuid.dart';

class DesignerPage extends StatefulWidget {
  const DesignerPage({super.key});

  @override
  State<DesignerPage> createState() => _DesignerPageState();
}

class _DesignerPageState extends State<DesignerPage> {
  static const _uuid = Uuid();
  static const _canvasScale = 3.0;

  final FlutterReportPrinter _printer = FlutterReportPrinter();
  final List<Map<String, dynamic>> _elements = [];

  String _paperType = 'thermal';
  double _widthMm = 80;
  double _heightMm = 200;
  bool _autoHeight = true;
  String? _selectedId;

  final Map<String, dynamic> _mockData = {
    'shop': {'name': 'ร้าน Dexter Coffee', 'branch': 'นิมมาน'},
    'orderId': 'ORD-001',
    'date': '12/08/2026',
    'customer': {'name': 'คุณสมชาย'},
    'items': [
      {'name': 'ลาเต้ร้อน', 'qty': 2, 'price': 65},
      {'name': 'ครัวซองต์', 'qty': 1, 'price': 85},
    ],
    'total': 215,
    'note': 'ขอบคุณครับ',
  };

  Map<String, dynamic> get _templateJson => {
        'id': 'custom_template',
        'version': 1,
        'paper': {
          'type': _paperType,
          'widthMm': _widthMm,
          'heightMm': _heightMm,
          'autoHeight': _autoHeight,
          'marginMm': 3,
        },
        'elements': _elements,
      };

  Map<String, dynamic>? get _selectedElement {
    for (final element in _elements) {
      if (element['id'] == _selectedId) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Designer'),
        actions: [
          _paperTypeSelector(),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Export JSON',
            onPressed: _showTemplateJson,
          ),
        ],
      ),
      body: isWide
          ? Row(children: [_leftPanel(), _canvas(), _rightPanel()])
          : Column(
              children: [
                _canvas(),
                SizedBox(
                  height: 230,
                  child: Row(
                    children: [
                      Expanded(child: _leftPanel(expandWidth: true)),
                      Expanded(child: _rightPanel(expandWidth: true)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _paperTypeSelector() => DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _paperType,
          items: const [
            DropdownMenuItem(value: 'thermal', child: Text('Thermal')),
            DropdownMenuItem(value: 'a4', child: Text('A4')),
            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _paperType = value;
              switch (value) {
                case 'thermal':
                  _widthMm = 80;
                  _heightMm = 200;
                  _autoHeight = true;
                  break;
                case 'a4':
                  _widthMm = 210;
                  _heightMm = 297;
                  _autoHeight = false;
                  break;
                case 'pdf':
                  _widthMm = 80;
                  _heightMm = 200;
                  _autoHeight = false;
                  break;
              }
            });
          },
        ),
      );

  Widget _leftPanel({bool expandWidth = false}) => SizedBox(
        width: expandWidth ? null : 180,
        child: Material(
          color: Colors.grey.shade100,
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  'Add Element',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _addButton('Text', Icons.text_fields, 'text'),
              _addButton('Dynamic {{field}}', Icons.data_object, 'dynamic_text'),
              _addButton('Line', Icons.horizontal_rule, 'line'),
              _addButton('Table {{items}}', Icons.table_chart, 'table'),
              _addButton('QR Code', Icons.qr_code, 'qrcode'),
              _addButton('Barcode', Icons.view_week, 'barcode'),
              const Divider(),
              ListTile(
                dense: true,
                title: Text('Paper: ${_widthMm.toStringAsFixed(0)} mm'),
              ),
              Slider(
                value: _widthMm.clamp(48, 210).toDouble(),
                min: 48,
                max: 210,
                divisions: 162,
                label: '${_widthMm.toStringAsFixed(0)} mm',
                onChanged: (value) => setState(() => _widthMm = value),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Auto Height'),
                value: _autoHeight,
                onChanged: (value) => setState(() => _autoHeight = value),
              ),
            ],
          ),
        ),
      );

  Widget _addButton(String label, IconData icon, String type) => ListTile(
        dense: true,
        leading: Icon(icon, size: 18),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        onTap: () => _addElement(type),
      );

  Widget _canvas() => Expanded(
        flex: 3,
        child: ColoredBox(
          color: Colors.grey.shade300,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(100),
            child: Center(
              child: Container(
                width: _widthMm * _canvasScale,
                height: (_autoHeight ? 200 : _heightMm) * _canvasScale,
                color: Colors.white,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _elements
                      .map(_positionedElement)
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _positionedElement(Map<String, dynamic> element) {
    final selected = element['id'] == _selectedId;
    return Positioned(
      left: _number(element['x']) * _canvasScale,
      top: _number(element['y']) * _canvasScale,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = element['id']?.toString()),
        onPanUpdate: (details) {
          setState(() {
            final width = _number(element['w']);
            final maxX = (_widthMm - width).clamp(0, _widthMm).toDouble();
            element['x'] =
                (_number(element['x']) + details.delta.dx / _canvasScale)
                    .clamp(0, maxX)
                    .toDouble();
            element['y'] =
                (_number(element['y']) + details.delta.dy / _canvasScale)
                    .clamp(0, 1000)
                    .toDouble();
          });
        },
        child: Container(
          width: _number(element['w']) * _canvasScale,
          height: _number(element['h']) * _canvasScale,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300,
              width: selected ? 2 : 0.5,
            ),
            color: selected ? Colors.blue.withValues(alpha: 0.08) : null,
          ),
          child: _elementPreview(element),
        ),
      ),
    );
  }

  Widget _elementPreview(Map<String, dynamic> element) {
    final type = element['type'];
    if (type == 'line') return const Divider(height: 1, thickness: 1);
    if (type == 'qrcode') return const FittedBox(child: Icon(Icons.qr_code));
    if (type == 'barcode') return const FittedBox(child: Icon(Icons.view_week));
    if (type == 'table') {
      return ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Text(
            element['key']?.toString() ?? '{{items}}',
            style: const TextStyle(fontSize: 8),
          ),
        ),
      );
    }

    final style = _style(element);
    return Align(
      alignment: _flutterAlignment(style['align']?.toString()),
      child: Text(
        element['key']?.toString() ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: _number(style['fontSize'], fallback: 10) * 0.8,
          fontWeight:
              style['bold'] == true ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _rightPanel({bool expandWidth = false}) {
    final selected = _selectedElement;
    if (selected == null) {
      return SizedBox(
        width: expandWidth ? null : 280,
        child: Material(
          color: Colors.grey.shade50,
          child: const Center(child: Text('Select an element to edit')),
        ),
      );
    }

    final style = _style(selected);
    return SizedBox(
      width: expandWidth ? null : 280,
      child: Material(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView(
            children: [
              const Text(
                'Properties',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('key-${selected['id']}-${selected['key']}'),
                initialValue: selected['key']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Key / Text'),
                onFieldSubmitted: (value) =>
                    setState(() => selected['key'] = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(selected, 'x', 'X')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberField(selected, 'y', 'Y')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _numberField(selected, 'w', 'W')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberField(selected, 'h', 'H')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Font'),
                  Expanded(
                    child: Slider(
                      value: _number(style['fontSize'], fallback: 10)
                          .clamp(6, 30)
                          .toDouble(),
                      min: 6,
                      max: 30,
                      onChanged: (value) =>
                          setState(() => style['fontSize'] = value),
                    ),
                  ),
                  Text(
                    _number(style['fontSize'], fallback: 10)
                        .toStringAsFixed(0),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bold'),
                value: style['bold'] == true,
                onChanged: (value) =>
                    setState(() => style['bold'] = value == true),
              ),
              DropdownButtonFormField<String>(
                initialValue: style['align']?.toString() ?? 'left',
                decoration: const InputDecoration(labelText: 'Alignment'),
                items: const [
                  DropdownMenuItem(value: 'left', child: Text('Left')),
                  DropdownMenuItem(value: 'center', child: Text('Center')),
                  DropdownMenuItem(value: 'right', child: Text('Right')),
                ],
                onChanged: (value) =>
                    setState(() => style['align'] = value ?? 'left'),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete element'),
                onPressed: _deleteSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    Map<String, dynamic> element,
    String key,
    String label,
  ) {
    return TextFormField(
      key: ValueKey('$key-${element['id']}-${element[key]}'),
      initialValue: _number(element[key]).toStringAsFixed(1),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onFieldSubmitted: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) setState(() => element[key] = parsed);
      },
    );
  }

  void _addElement(String type) {
    final id = _uuid.v4();
    final element = <String, dynamic>{
      'id': id,
      'type': type,
      'key': _defaultKey(type),
      'x': 5.0,
      'y': 5.0 + (_elements.length * 12),
      'w': type == 'line'
          ? (_widthMm - 10).clamp(10, _widthMm).toDouble()
          : 60.0,
      'h': type == 'qrcode' || type == 'barcode' ? 30.0 : 8.0,
      'style': {
        'fontSize': type == 'text' ? 12.0 : 10.0,
        'bold': false,
        'align': 'left',
      },
    };
    if (type == 'table') {
      element['columns'] = [
        {'key': 'name', 'label': 'Item'},
        {'key': 'qty', 'label': 'Qty'},
        {'key': 'price', 'label': 'Price'},
      ];
      element['h'] = 35.0;
    }
    setState(() {
      _elements.add(element);
      _selectedId = id;
    });
  }

  String _defaultKey(String type) {
    switch (type) {
      case 'text':
        return 'Sample text';
      case 'table':
        return '{{items}}';
      case 'qrcode':
      case 'barcode':
        return '{{orderId}}';
      case 'line':
        return '';
      default:
        return '{{shop.name}}';
    }
  }

  void _deleteSelected() {
    setState(() {
      _elements.removeWhere((element) => element['id'] == _selectedId);
      _selectedId = null;
    });
  }

  Future<void> _previewPdf() async {
    try {
      final pdf = await _printer.generatePdf(
        templateJson: _templateJson,
        data: _mockData,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Preview')),
            body: PdfPreview(build: (_) async => pdf),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to generate preview: $error')),
      );
    }
  }

  Future<void> _showTemplateJson() {
    final json = const JsonEncoder.withIndent('  ').convert(_templateJson);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template JSON'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _style(Map<String, dynamic> element) {
    final existing = element['style'];
    if (existing is Map<String, dynamic>) return existing;
    final style = Map<String, dynamic>.from(existing as Map? ?? const {});
    element['style'] = style;
    return style;
  }

  double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Alignment _flutterAlignment(String? value) {
    switch (value) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
