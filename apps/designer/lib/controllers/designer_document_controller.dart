import 'dart:convert';

class DesignerDocumentController {
  DesignerDocumentController({Map<String, dynamic>? initialTemplate}) {
    if (initialTemplate != null) {
      loadTemplate(initialTemplate, clearHistory: true);
    }
  }

  static const double gridSizeMm = 5;

  Map<String, dynamic> _document = _newDocument();
  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  String? _interactionSnapshot;

  String? selectedId;
  double zoom = 1;

  Map<String, dynamic> get document => _deepCopy(_document);
  List<Map<String, dynamic>> get elements =>
      (_document['elements'] as List<dynamic>)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList(growable: false);

  Map<String, dynamic> get paper =>
      Map<String, dynamic>.from(_document['paper'] as Map);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Map<String, dynamic>? get selectedElement {
    final id = selectedId;
    if (id == null) return null;
    for (final value in _document['elements'] as List<dynamic>) {
      final element = value as Map<String, dynamic>;
      if (element['id'] == id) return element;
    }
    return null;
  }

  void createNew({String id = 'untitled'}) {
    _recordUndo();
    _document = _newDocument(id: id);
    selectedId = null;
  }

  void loadTemplate(
    Map<String, dynamic> template, {
    bool clearHistory = false,
  }) {
    _validateTemplate(template);
    if (clearHistory) {
      _undoStack.clear();
      _redoStack.clear();
    } else {
      _recordUndo();
    }
    _document = _deepCopy(template);
    _document['version'] ??= 1;
    selectedId = null;
  }

  void setPaper({
    String? type,
    double? widthMm,
    double? heightMm,
    bool? autoHeight,
  }) {
    _recordUndo();
    final paper = _document['paper'] as Map<String, dynamic>;
    if (type != null) paper['type'] = type;
    if (widthMm != null) paper['widthMm'] = widthMm;
    if (heightMm != null) paper['heightMm'] = heightMm;
    if (autoHeight != null) paper['autoHeight'] = autoHeight;
  }

  void addElement(Map<String, dynamic> element) {
    _recordUndo();
    (_document['elements'] as List<dynamic>).add(_deepCopy(element));
    selectedId = element['id']?.toString();
  }

  void deleteSelected() {
    final id = selectedId;
    if (id == null) return;
    _recordUndo();
    (_document['elements'] as List<dynamic>)
        .removeWhere((value) => (value as Map)['id'] == id);
    selectedId = null;
  }

  void updateSelected(String key, dynamic value) {
    final element = selectedElement;
    if (element == null) return;
    _recordUndo();
    element[key] = value;
  }

  void updateSelectedStyle(String key, dynamic value) {
    final element = selectedElement;
    if (element == null) return;
    _recordUndo();
    _style(element)[key] = value;
  }

  void moveSelected(double x, double y, {bool snap = true}) {
    final element = selectedElement;
    if (element == null) return;
    _recordUndo();
    element['x'] = snap ? snapMm(x) : x;
    element['y'] = snap ? snapMm(y) : y;
  }

  void beginInteraction() {
    _interactionSnapshot ??= jsonEncode(_document);
  }

  void moveSelectedInteractive(double x, double y) {
    final element = selectedElement;
    if (element == null) return;
    element['x'] = x;
    element['y'] = y;
  }

  void endInteraction({bool snapPosition = true}) {
    final snapshot = _interactionSnapshot;
    _interactionSnapshot = null;
    if (snapshot == null) return;
    final element = selectedElement;
    if (snapPosition && element != null) {
      element['x'] = snapMm(_number(element['x']));
      element['y'] = snapMm(_number(element['y']));
    }
    if (snapshot != jsonEncode(_document)) {
      _undoStack.add(snapshot);
      if (_undoStack.length > 100) _undoStack.removeAt(0);
      _redoStack.clear();
    }
  }

  void resizeSelected(double width, double height, {bool snap = true}) {
    final element = selectedElement;
    if (element == null) return;
    _recordUndo();
    element['w'] = (snap ? snapMm(width) : width).clamp(1, 10000).toDouble();
    element['h'] = (snap ? snapMm(height) : height).clamp(1, 10000).toDouble();
  }

  void nudgeSelected(double dx, double dy) {
    final element = selectedElement;
    if (element == null) return;
    moveSelected(
      _number(element['x']) + dx,
      _number(element['y']) + dy,
      snap: false,
    );
  }

  void addTableColumn() {
    final element = selectedElement;
    if (element == null || element['type'] != 'table') return;
    _recordUndo();
    final columns = _columns(element);
    columns.add(<String, dynamic>{
      'key': 'field${columns.length + 1}',
      'label': 'Column ${columns.length + 1}',
      'width': 1.0,
      'alignment': 'left',
    });
  }

  void updateTableColumn(int index, String key, dynamic value) {
    final element = selectedElement;
    if (element == null || element['type'] != 'table') return;
    final columns = _columns(element);
    if (index < 0 || index >= columns.length) return;
    if (key == 'width') {
      final parsed = value is num ? value.toDouble() : double.tryParse('$value');
      if (parsed == null || parsed <= 0) return;
      value = parsed;
    }
    _recordUndo();
    columns[index][key] = value;
  }

  void removeTableColumn(int index) {
    final element = selectedElement;
    if (element == null || element['type'] != 'table') return;
    final columns = _columns(element);
    if (index < 0 || index >= columns.length) return;
    _recordUndo();
    columns.removeAt(index);
  }

  void reorderTableColumn(int from, int to) {
    final element = selectedElement;
    if (element == null || element['type'] != 'table') return;
    final columns = _columns(element);
    if (from < 0 || from >= columns.length || to < 0 || to >= columns.length) {
      return;
    }
    if (from == to) return;
    _recordUndo();
    final column = columns.removeAt(from);
    columns.insert(to, column);
  }

  void setZoom(double value) {
    zoom = value.clamp(0.5, 2).toDouble();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(jsonEncode(_document));
    _document = _decode(_undoStack.removeLast());
    selectedId = null;
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(jsonEncode(_document));
    _document = _decode(_redoStack.removeLast());
    selectedId = null;
  }

  static double snapMm(double value) =>
      (value / gridSizeMm).round() * gridSizeMm;

  void _recordUndo() {
    final snapshot = jsonEncode(_document);
    if (_undoStack.isEmpty || _undoStack.last != snapshot) {
      _undoStack.add(snapshot);
      if (_undoStack.length > 100) _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  static List<Map<String, dynamic>> _columns(Map<String, dynamic> element) {
    final raw = element['columns'];
    if (raw is List) {
      final normalized = raw
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
      element['columns'] = normalized;
      return normalized;
    }
    final columns = <Map<String, dynamic>>[];
    element['columns'] = columns;
    return columns;
  }

  static Map<String, dynamic> _style(Map<String, dynamic> element) {
    final raw = element['style'];
    if (raw is Map<String, dynamic>) return raw;
    final style = Map<String, dynamic>.from(raw as Map? ?? const {});
    element['style'] = style;
    return style;
  }

  static void _validateTemplate(Map<String, dynamic> template) {
    if (template['paper'] is! Map || template['elements'] is! List) {
      throw const FormatException(
        'Template must contain a paper object and elements list.',
      );
    }
  }

  static Map<String, dynamic> _newDocument({String id = 'untitled'}) =>
      <String, dynamic>{
        'id': id,
        'version': 1,
        'paper': <String, dynamic>{
          'type': 'thermal',
          'widthMm': 80.0,
          'heightMm': 200.0,
          'autoHeight': true,
          'marginMm': 3.0,
        },
        'elements': <Map<String, dynamic>>[],
      };

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
      _decode(jsonEncode(value));

  static Map<String, dynamic> _decode(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
