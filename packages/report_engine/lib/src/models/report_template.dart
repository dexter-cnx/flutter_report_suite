enum ReportPaperType { thermal, a4, pdf, custom }

enum ReportElementType {
  text,
  dynamicText,
  line,
  barcode,
  qrcode,
  table,
  image
}

class PaperConfig {
  const PaperConfig({
    required this.type,
    required this.widthMm,
    this.heightMm,
    this.autoHeight = false,
    this.marginMm = 3,
  });

  final String type;
  final double widthMm;
  final double? heightMm;
  final bool autoHeight;
  final double marginMm;

  factory PaperConfig.fromJson(Map<String, dynamic> json) => PaperConfig(
        type: json['type']?.toString() ?? 'a4',
        widthMm: _asDouble(json['widthMm'], fallback: 80),
        heightMm: json['heightMm'] == null ? null : _asDouble(json['heightMm']),
        autoHeight: json['autoHeight'] == true,
        marginMm: _asDouble(json['marginMm'], fallback: 3),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'widthMm': widthMm,
        if (heightMm != null) 'heightMm': heightMm,
        'autoHeight': autoHeight,
        'marginMm': marginMm,
      };
}

class ReportElement {
  const ReportElement({
    required this.id,
    required this.type,
    this.key,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.style = const {},
    this.columns = const [],
  });

  final String id;
  final String type;
  final String? key;
  final double x;
  final double y;
  final double w;
  final double h;
  final Map<String, dynamic> style;
  final List<Map<String, dynamic>> columns;

  factory ReportElement.fromJson(Map<String, dynamic> json) => ReportElement(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'text',
        key: json['key']?.toString(),
        x: _asDouble(json['x']),
        y: _asDouble(json['y']),
        w: _asDouble(json['w']),
        h: _asDouble(json['h']),
        style: Map<String, dynamic>.from(json['style'] as Map? ?? const {}),
        columns: (json['columns'] as List? ?? const [])
            .whereType<Map>()
            .map((column) => Map<String, dynamic>.from(column))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (key != null) 'key': key,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'style': style,
        if (columns.isNotEmpty) 'columns': columns,
      };
}

class ReportTemplate {
  const ReportTemplate({
    required this.id,
    required this.version,
    required this.paper,
    required this.elements,
  });

  final String id;
  final int version;
  final PaperConfig paper;
  final List<ReportElement> elements;

  factory ReportTemplate.fromJson(Map<String, dynamic> json) => ReportTemplate(
        id: json['id']?.toString() ?? 'template',
        version: (json['version'] as num?)?.toInt() ?? 1,
        paper: PaperConfig.fromJson(
          Map<String, dynamic>.from(json['paper'] as Map? ?? const {}),
        ),
        elements: (json['elements'] as List? ?? const [])
            .whereType<Map>()
            .map((element) => ReportElement.fromJson(
                  Map<String, dynamic>.from(element),
                ))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'paper': paper.toJson(),
        'elements': elements.map((element) => element.toJson()).toList(),
      };
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
