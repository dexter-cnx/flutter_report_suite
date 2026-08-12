import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:report_engine/report_engine.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../controllers/designer_document_controller.dart';
import '../design_system/design_system.dart';
import '../services/template_file_exporter.dart';

class DesignerPage extends StatefulWidget {
  const DesignerPage({
    super.key,
    this.initialTemplate,
    this.initialTemplateId,
  });

  final Map<String, dynamic>? initialTemplate;
  final String? initialTemplateId;

  @override
  State<DesignerPage> createState() => _DesignerPageState();
}

class _DesignerPageState extends State<DesignerPage> {
  static const _uuid = Uuid();
  static const _canvasScale = 3.0;

  final FlutterReportPrinter _printer = FlutterReportPrinter();
  final TemplateStorageService _storage = TemplateStorageService();
  final FocusNode _keyboardFocus = FocusNode();

  late final DesignerDocumentController _document;
  String? _templateId;
  bool _storageReady = false;
  bool _mediumElementsVisible = false;

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

  @override
  void initState() {
    super.initState();
    _document =
        DesignerDocumentController(initialTemplate: widget.initialTemplate);
    _templateId = widget.initialTemplateId;
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= DesignerLayout.compactDesktopBreakpoint;
    final medium = width >= DesignerLayout.collapsiblePanelBreakpoint;

    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: SafeArea(
          child: desktop
              ? _desktopWorkspace()
              : medium
                  ? _mediumWorkspace()
                  : _compactWorkspace(),
        ),
      ),
    );
  }

  Widget _desktopWorkspace() {
    return DesignerAppShell(
      toolbar: _toolbar(),
      leftPanel: _leftPanel(expandWidth: true),
      workspace: _canvas(),
      rightPanel: _rightPanel(expandWidth: true),
      statusBar: _statusBar(),
    );
  }

  Widget _mediumWorkspace() {
    return DesignerAppShell(
      toolbar: _toolbar(showElementsToggle: true),
      leftPanel: _mediumElementsVisible ? _leftPanel(expandWidth: true) : null,
      workspace: _canvas(),
      rightPanel: _rightPanel(expandWidth: true),
      statusBar: _statusBar(),
    );
  }

  Widget _compactWorkspace() {
    return Column(
      children: [
        SizedBox(
          height: DesignerLayout.topToolbarHeight,
          child: _toolbar(),
        ),
        Expanded(child: _canvas()),
        SizedBox(
          height: 270,
          child: Row(
            children: [
              Expanded(child: _leftPanel(expandWidth: true)),
              Expanded(child: _rightPanel(expandWidth: true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBar() {
    final paper = _document.paper;
    final widthMm = _number(paper['widthMm'], fallback: 80);
    final heightMm = paper['autoHeight'] == true
        ? 200.0
        : _number(paper['heightMm'], fallback: 200);

    return DesignerStatusBar(
      leading: Text(
        '${paper['type']?.toString().toUpperCase() ?? 'PDF'} · '
        '${widthMm.toStringAsFixed(1)} × ${heightMm.toStringAsFixed(1)} mm',
      ),
      center: const Text('5 mm snap grid · rulers in mm'),
      trailing: ZoomControl(
        value: _document.zoom,
        onChanged: (value) => setState(() => _document.setZoom(value)),
      ),
    );
  }

  Widget _toolbar({bool showElementsToggle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignerSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _templateId == null
                  ? 'Report Designer'
                  : 'Report Designer — $_templateId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignerTypography.appTitle,
            ),
          ),
          if (showElementsToggle) ...[
            ToolbarButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: 'Toggle Elements',
              selected: _mediumElementsVisible,
              onPressed: () => setState(
                () => _mediumElementsVisible = !_mediumElementsVisible,
              ),
            ),
            const SizedBox(width: DesignerSpacing.sm),
          ],
          ToolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: _document.canUndo ? _undo : null,
          ),
          const SizedBox(width: DesignerSpacing.xs),
          ToolbarButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: _document.canRedo ? _redo : null,
          ),
          const SizedBox(width: DesignerSpacing.sm),
          ToolbarButton(
            icon: Icons.picture_as_pdf,
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          const SizedBox(width: DesignerSpacing.sm),
          PopupMenuButton<String>(
            tooltip: 'Template actions',
            onSelected: _handleTemplateAction,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New')),
              PopupMenuItem(value: 'save', child: Text('Save')),
              PopupMenuItem(value: 'saveAs', child: Text('Save As')),
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'load', child: Text('Load')),
              PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'import', child: Text('Import JSON')),
              PopupMenuItem(value: 'export', child: Text('Export JSON')),
              PopupMenuItem(value: 'share', child: Text('Share JSON')),
              PopupMenuItem(value: 'json', child: Text('View JSON')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leftPanel({bool expandWidth = false}) {
    final paper = _document.paper;
    final paperType = paper['type']?.toString() ?? 'thermal';

    return Material(
      color: DesignerColors.panelBackground,
      child: ListView(
        children: [
          const PanelHeader(title: 'Elements'),
          _addButton('Text', Icons.text_fields, 'text'),
          _addButton('Dynamic {{field}}', Icons.data_object, 'dynamic_text'),
          _addButton('Line', Icons.horizontal_rule, 'line'),
          _addButton('Table {{items}}', Icons.table_chart, 'table'),
          _addButton('QR Code', Icons.qr_code, 'qrcode'),
          _addButton('Barcode', Icons.view_week, 'barcode'),
          const Divider(height: 1),
          const PanelHeader(title: 'Document'),
          Padding(
            padding: const EdgeInsets.all(DesignerSpacing.md),
            child: PropertyDropdown<String>(
              value: _validPaperType(paperType),
              label: 'Paper Type',
              items: const [
                DropdownMenuItem(value: 'thermal', child: Text('Thermal')),
                DropdownMenuItem(value: 'a4', child: Text('A4')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              ],
              onChanged: _changePaperType,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignerSpacing.md,
            ),
            child: Text(
              'Paper width ${_number(paper['widthMm']).toStringAsFixed(1)} mm',
              style: DesignerTypography.helper,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignerSpacing.sm,
              DesignerSpacing.sm,
              DesignerSpacing.sm,
              DesignerSpacing.md,
            ),
            child: Slider(
              value: _document.zoom,
              min: 0.5,
              max: 2,
              divisions: 15,
              onChanged: (value) => setState(() => _document.setZoom(value)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(String label, IconData icon, String type) => ListTile(
        dense: true,
        minVerticalPadding: 0,
        leading: Icon(icon, size: 18, color: DesignerColors.textSecondary),
        title: Text(label, style: DesignerTypography.body),
        onTap: () => _addElement(type),
      );

  Widget _canvas() {
    final paper = _document.paper;
    final widthMm = _number(paper['widthMm'], fallback: 80);
    final heightMm = paper['autoHeight'] == true
        ? 200.0
        : _number(paper['heightMm'], fallback: 200);
    final scale = _canvasScale * _document.zoom;

    return CanvasViewport(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CanvasRuler(
            axis: CanvasRulerAxis.vertical,
            lengthMm: heightMm,
            scale: scale,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CanvasRuler(
                axis: CanvasRulerAxis.horizontal,
                lengthMm: widthMm,
                scale: scale,
              ),
              CanvasPage(
                width: widthMm * scale,
                height: heightMm * scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(child: CanvasGuideOverlay()),
                    ..._document.elements.map(
                      (element) => _positionedElement(
                        element,
                        scale,
                        widthMm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _positionedElement(
    Map<String, dynamic> element,
    double scale,
    double widthMm,
  ) {
    final selected = element['id'] == _document.selectedId;
    final elementWidth = _number(element['w'], fallback: 20) * scale;
    final elementHeight = _number(element['h'], fallback: 8) * scale;

    return Positioned(
      left: _number(element['x']) * scale,
      top: _number(element['y']) * scale,
      child: CanvasSelectionOverlay(
        selected: selected,
        child: GestureDetector(
          onTap: () => setState(
            () => _document.selectedId = element['id']?.toString(),
          ),
          onPanStart: (_) {
            setState(() {
              _document.selectedId = element['id']?.toString();
              _document.beginInteraction();
            });
          },
          onPanUpdate: (details) {
            final current = _document.selectedElement;
            if (current == null) return;
            final currentWidth = _number(current['w']);
            final maxX =
                (widthMm - currentWidth).clamp(0, widthMm).toDouble();
            final x = (_number(current['x']) + details.delta.dx / scale)
                .clamp(0, maxX)
                .toDouble();
            final y = (_number(current['y']) + details.delta.dy / scale)
                .clamp(0, 1000)
                .toDouble();
            setState(() => _document.moveSelectedInteractive(x, y));
          },
          onPanEnd: (_) => setState(_document.endInteraction),
          onPanCancel: () => setState(_document.endInteraction),
          child: Container(
            width: elementWidth,
            height: elementHeight,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: selected
                  ? null
                  : Border.all(
                      color: DesignerColors.borderDefault,
                      width: 0.5,
                    ),
            ),
            child: _elementPreview(element),
          ),
        ),
      ),
    );
  }

  Widget _elementPreview(Map<String, dynamic> element) {
    final type = element['type'];
    if (type == 'line') return const Divider(height: 1, thickness: 1);
    if (type == 'qrcode') return const FittedBox(child: Icon(Icons.qr_code));
    if (type == 'barcode') {
      return const FittedBox(child: Icon(Icons.view_week));
    }
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
    final selected = _document.selectedElement;
    if (selected == null) {
      return const Material(
        color: DesignerColors.panelBackground,
        child: Column(
          children: [
            PanelHeader(title: 'Inspector'),
            Expanded(child: Center(child: Text('Select an element to edit'))),
          ],
        ),
      );
    }

    final style = _style(selected);
    return Material(
      color: DesignerColors.panelBackground,
      child: Column(
        children: [
          const PanelHeader(title: 'Inspector'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignerSpacing.md),
              children: [
                TextFormField(
                  key: ValueKey('key-${selected['id']}-${selected['key']}'),
                  initialValue: selected['key']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Key / Text'),
                  onFieldSubmitted: (value) => setState(
                    () => _document.updateSelected('key', value),
                  ),
                ),
                const SizedBox(height: DesignerSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _numberField(selected, 'x', 'X')),
                    const SizedBox(width: DesignerSpacing.sm),
                    Expanded(child: _numberField(selected, 'y', 'Y')),
                  ],
                ),
                const SizedBox(height: DesignerSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _numberField(selected, 'w', 'W')),
                    const SizedBox(width: DesignerSpacing.sm),
                    Expanded(child: _numberField(selected, 'h', 'H')),
                  ],
                ),
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
                        onChanged: (value) => setState(
                          () => _document.updateSelectedStyle(
                            'fontSize',
                            value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bold'),
                  value: style['bold'] == true,
                  onChanged: (value) => setState(
                    () => _document.updateSelectedStyle(
                      'bold',
                      value == true,
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  // Flutter 3.32.7 still requires `value` here.
                  // ignore: deprecated_member_use
                  value: _validAlignment(style['align']),
                  decoration: const InputDecoration(labelText: 'Alignment'),
                  items: const [
                    DropdownMenuItem(value: 'left', child: Text('Left')),
                    DropdownMenuItem(value: 'center', child: Text('Center')),
                    DropdownMenuItem(value: 'right', child: Text('Right')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(
                      () => _document.updateSelectedStyle('align', value),
                    );
                  },
                ),
                if (selected['type'] == 'table') ...[
                  const Divider(height: 28),
                  _tableColumnEditor(selected),
                ],
                const SizedBox(height: DesignerSpacing.lg),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete element'),
                  onPressed: () => setState(_document.deleteSelected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableColumnEditor(Map<String, dynamic> selected) {
    final columns = (selected['columns'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Table Columns',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: 'Add column',
              onPressed: () => setState(_document.addTableColumn),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        for (var index = 0; index < columns.length; index++)
          _columnCard(columns[index], index, columns.length),
      ],
    );
  }

  Widget _columnCard(
    Map<String, dynamic> column,
    int index,
    int columnCount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('column-key-$index-${column['key']}'),
                    initialValue: column['key']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'key'),
                    onFieldSubmitted: (value) => setState(
                      () => _document.updateTableColumn(index, 'key', value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('column-label-$index-${column['label']}'),
                    initialValue: column['label']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'label'),
                    onFieldSubmitted: (value) => setState(
                      () => _document.updateTableColumn(index, 'label', value),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('column-width-$index-${column['width']}'),
                    initialValue: '${column['width'] ?? 1}',
                    decoration: const InputDecoration(labelText: 'width'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onFieldSubmitted: (value) => setState(
                      () => _document.updateTableColumn(index, 'width', value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // Flutter 3.32.7 still requires `value` here.
                    // ignore: deprecated_member_use
                    value: _validAlignment(
                      column['alignment'] ?? column['align'],
                    ),
                    decoration: const InputDecoration(labelText: 'alignment'),
                    items: const [
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'center', child: Text('Center')),
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(
                        () => _document.updateTableColumn(
                          index,
                          'alignment',
                          value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Move column up',
                  onPressed: index > 0
                      ? () => setState(
                            () =>
                                _document.reorderTableColumn(index, index - 1),
                          )
                      : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move column down',
                  onPressed: index < columnCount - 1
                      ? () => setState(
                            () =>
                                _document.reorderTableColumn(index, index + 1),
                          )
                      : null,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove column',
                  onPressed: () => setState(
                    () => _document.removeTableColumn(index),
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
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
        if (parsed == null) return;
        setState(() {
          final selected = _document.selectedElement;
          if (selected == null) return;
          if (key == 'x' || key == 'y') {
            _document.moveSelected(
              key == 'x' ? parsed : _number(selected['x']),
              key == 'y' ? parsed : _number(selected['y']),
            );
          } else {
            _document.resizeSelected(
              key == 'w' ? parsed : _number(selected['w']),
              key == 'h' ? parsed : _number(selected['h']),
            );
          }
        });
      },
    );
  }

  void _addElement(String type) {
    final id = _uuid.v4();
    final count = _document.elements.length;
    final element = <String, dynamic>{
      'id': id,
      'type': type,
      'key': _defaultKey(type),
      'x': 5.0,
      'y': DesignerDocumentController.snapMm(5.0 + count * 12),
      'w': 60.0,
      'h': type == 'qrcode' || type == 'barcode' ? 30.0 : 10.0,
      'style': <String, dynamic>{
        'fontSize': type == 'text' ? 12.0 : 10.0,
        'bold': false,
        'align': 'left',
      },
    };
    if (type == 'table') {
      element['columns'] = <Map<String, dynamic>>[
        {
          'key': 'name',
          'label': 'Item',
          'width': 2.0,
          'alignment': 'left',
        },
        {
          'key': 'qty',
          'label': 'Qty',
          'width': 1.0,
          'alignment': 'right',
        },
        {
          'key': 'price',
          'label': 'Price',
          'width': 1.0,
          'alignment': 'right',
        },
      ];
      element['h'] = 35.0;
    }
    setState(() => _document.addElement(element));
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

  void _changePaperType(String? value) {
    if (value == null) return;
    setState(() {
      switch (value) {
        case 'a4':
          _document.setPaper(
            type: value,
            widthMm: 210,
            heightMm: 297,
            autoHeight: false,
          );
          break;
        case 'thermal':
          _document.setPaper(
            type: value,
            widthMm: 80,
            heightMm: 200,
            autoHeight: true,
          );
          break;
        default:
          _document.setPaper(type: value, autoHeight: false);
      }
    });
  }

  Future<void> _handleTemplateAction(String action) async {
    switch (action) {
      case 'new':
        setState(() {
          _document.createNew();
          _templateId = null;
        });
        break;
      case 'save':
        await _save();
        break;
      case 'saveAs':
        await _saveAs();
        break;
      case 'rename':
        await _rename();
        break;
      case 'load':
        await _load();
        break;
      case 'duplicate':
        await _duplicate();
        break;
      case 'delete':
        await _deleteTemplate();
        break;
      case 'import':
        await _importJson();
        break;
      case 'export':
        await _exportJson();
        break;
      case 'share':
        await _shareJson();
        break;
      case 'json':
        await _showTemplateJson();
        break;
    }
  }

  Future<void> _ensureStorage() async {
    if (_storageReady) return;
    await _storage.init();
    _storageReady = true;
  }

  Future<String?> _askForId(
    String title, {
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result == null || result.isEmpty ? null : result;
  }

  Future<void> _save() async {
    try {
      await _ensureStorage();
      final id = _templateId ?? await _askForId('Save Template');
      if (id == null) return;
      final template = _document.document..['id'] = id;
      await _storage.saveTemplate(id, template);
      if (!mounted) return;
      setState(() => _templateId = id);
      _showMessage('Saved "$id".');
    } catch (error) {
      _showError('Unable to save template: $error');
    }
  }

  Future<void> _saveAs() async {
    final id = await _askForId('Save Template As');
    if (id == null) return;
    try {
      await _ensureStorage();
      if (await _storage.containsTemplate(id)) {
        throw StateError('Template "$id" already exists.');
      }
      final template = _document.document..['id'] = id;
      await _storage.saveTemplate(id, template);
      if (!mounted) return;
      setState(() => _templateId = id);
      _showMessage('Saved copy as "$id".');
    } catch (error) {
      _showError('Unable to save copy: $error');
    }
  }

  Future<void> _rename() async {
    final current = _templateId;
    if (current == null) {
      await _saveAs();
      return;
    }
    final target = await _askForId(
      'Rename Template',
      initialValue: current,
    );
    if (target == null || target == current) return;
    try {
      await _ensureStorage();
      await _storage.renameTemplate(current, target);
      if (!mounted) return;
      setState(() => _templateId = target);
      _showMessage('Renamed to "$target".');
    } catch (error) {
      _showError('Unable to rename template: $error');
    }
  }

  Future<void> _load() async {
    try {
      await _ensureStorage();
      final ids = await _storage.getAllTemplateIds();
      if (!mounted) return;
      if (ids.isEmpty) {
        _showMessage('No saved templates yet.');
        return;
      }
      final id = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Load Template'),
          children: ids
              .map(
                (id) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, id),
                  child: Text(id),
                ),
              )
              .toList(),
        ),
      );
      if (id == null) return;
      final template = await _storage.getTemplate(id);
      if (template == null || !mounted) return;
      setState(() {
        _document.loadTemplate(template);
        _templateId = id;
      });
    } catch (error) {
      _showError('Unable to load template: $error');
    }
  }

  Future<void> _duplicate() async {
    final current = _templateId;
    if (current == null) {
      _showMessage('Save the template before duplicating it.');
      return;
    }
    final target = await _askForId(
      'Duplicate Template',
      initialValue: '$current-copy',
    );
    if (target == null) return;
    try {
      await _ensureStorage();
      await _storage.duplicateTemplate(current, target);
      _showMessage('Created "$target".');
    } catch (error) {
      _showError('Unable to duplicate template: $error');
    }
  }

  Future<void> _deleteTemplate() async {
    final current = _templateId;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Template?'),
            content: Text('Delete "$current" from local storage?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _ensureStorage();
      await _storage.deleteTemplate(current);
      if (!mounted) return;
      setState(() => _templateId = null);
      _showMessage('Deleted "$current".');
    } catch (error) {
      _showError('Unable to delete template: $error');
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw const FormatException('Unable to read selected JSON file.');
      }
      final template = _storage.decodeTemplate(utf8.decode(bytes));
      if (!mounted) return;
      setState(() {
        _document.loadTemplate(template);
        _templateId = null;
      });
      _showMessage('Imported JSON as an unsaved working copy.');
    } catch (error) {
      _showError('Unable to import JSON: $error');
    }
  }

  Future<void> _exportJson() async {
    try {
      final json =
          const JsonEncoder.withIndent(' ').convert(_document.document);
      final exported = await exportTemplateJsonFile(
        fileName: '${_templateId ?? 'report-template'}.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (exported) {
        _showMessage('JSON export completed.');
      }
    } catch (error) {
      _showError('Unable to export JSON: $error');
    }
  }

  Future<void> _shareJson() async {
    try {
      final json =
          const JsonEncoder.withIndent('  ').convert(_document.document);
      await Share.share(
        json,
        subject: '${_templateId ?? 'Report Template'}.json',
      );
    } catch (error) {
      _showError('Unable to share JSON: $error');
    }
  }

  Future<void> _previewPdf() async {
    try {
      final pdf = await _printer.generatePdf(
        templateJson: _document.document,
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
      _showError('Unable to generate preview: $error');
    }
  }

  Future<void> _showTemplateJson() {
    final json = const JsonEncoder.withIndent('  ').convert(_document.document);
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    if (command && event.logicalKey == LogicalKeyboardKey.keyZ) {
      keyboard.isShiftPressed ? _redo() : _undo();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      setState(_document.deleteSelected);
      return;
    }

    final step = keyboard.isShiftPressed ? 5.0 : 1.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _document.nudgeSelected(-step, 0));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() => _document.nudgeSelected(step, 0));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _document.nudgeSelected(0, -step));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _document.nudgeSelected(0, step));
    }
  }

  void _undo() => setState(_document.undo);
  void _redo() => setState(_document.redo);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) => _showMessage(message);

  Map<String, dynamic> _style(Map<String, dynamic> element) =>
      Map<String, dynamic>.from(element['style'] as Map? ?? const {});

  double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _validPaperType(String value) =>
      const {'thermal', 'a4', 'pdf'}.contains(value) ? value : 'pdf';

  String _validAlignment(dynamic value) {
    final alignment = value?.toString() ?? 'left';
    return const {'left', 'center', 'right'}.contains(alignment)
        ? alignment
        : 'left';
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
