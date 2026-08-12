import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TemplateStorageService {
  TemplateStorageService({this.boxName = defaultBoxName});

  static const defaultBoxName = 'report_templates';

  final String boxName;
  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box ??= await Hive.openBox<String>(boxName);
  }

  Future<Map<String, dynamic>> loadFromAssets(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return _decodeTemplate(source);
  }

  Future<void> saveTemplate(String id, Map<String, dynamic> template) async {
    final box = await _ensureBox();
    await box.put(id, jsonEncode(template));
  }

  Future<Map<String, dynamic>?> getTemplate(String id) async {
    final box = await _ensureBox();
    final raw = box.get(id);
    return raw == null ? null : _decodeTemplate(raw);
  }

  Future<List<String>> getAllTemplateIds() async {
    final box = await _ensureBox();
    return box.keys.map((key) => key.toString()).toList(growable: false);
  }

  Future<void> deleteTemplate(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
  }

  Future<Box<String>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(boxName);
    return _box!;
  }

  Map<String, dynamic> _decodeTemplate(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Report template must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
