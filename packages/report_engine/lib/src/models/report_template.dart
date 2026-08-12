
import 'dart:convert';

class PaperConfig {
  final String type; // thermal, a4, pdf, custom
  final double widthMm;
  final double? heightMm;
  final bool autoHeight;
  final double marginMm;

  PaperConfig({required this.type, required this.widthMm, this.heightMm, this.autoHeight = false, this.marginMm = 3});

  factory PaperConfig.fromJson(Map<String, dynamic> json) {
    return PaperConfig(
      type: json['type'] ?? 'a4',
      widthMm: (json['widthMm'] ?? 80).toDouble(),
      heightMm: json['heightMm']?.toDouble(),
      autoHeight: json['autoHeight'] ?? false,
      marginMm: (json['marginMm'] ?? 3).toDouble(),
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type, 'widthMm': widthMm, 'heightMm': heightMm, 'autoHeight': autoHeight, 'marginMm': marginMm
  };
}

class ReportElement {
  final String id;
  final String type; // text, dynamic_text, line, barcode, qrcode, table, image
  final String? key; // e.g. shop.name or {{orderId}}
  final double x, y, w, h;
  final Map<String, dynamic> style;
  final List<dynamic>? columns; // for table

  ReportElement({required this.id, required this.type, this.key, required this.x, required this.y, required this.w, required this.h, this.style = const {}, this.columns});

  factory ReportElement.fromJson(Map<String, dynamic> j) => ReportElement(
    id: j['id'], type: j['type'], key: j['key'],
    x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble(),
    w: (j['w'] as num).toDouble(), h: (j['h'] as num).toDouble(),
    style: j['style'] ?? {}, columns: j['columns']
  );
}

class ReportTemplate {
  final String id;
  final int version;
  final PaperConfig paper;
  final List<ReportElement> elements;

  ReportTemplate({required this.id, required this.version, required this.paper, required this.elements});

  factory ReportTemplate.fromJson(Map<String, dynamic> j) => ReportTemplate(
    id: j['id'], version: j['version'] ?? 1,
    paper: PaperConfig.fromJson(j['paper']),
    elements: (j['elements'] as List).map((e) => ReportElement.fromJson(e)).toList()
  );
}
