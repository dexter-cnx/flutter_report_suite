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
    return decodeTemplate(source);
  }

  Future<void> saveTemplate(String id, Map<String, dynamic> template) async {
    final normalizedId = _normalizeId(id);
    final normalizedTemplate = Map<String, dynamic>.from(template)
      ..['id'] = normalizedId
      ..putIfAbsent('version', () => 1);
    decodeTemplate(jsonEncode(normalizedTemplate));
    final box = await _ensureBox();
    await box.put(normalizedId, jsonEncode(normalizedTemplate));
  }

  Future<Map<String, dynamic>?> getTemplate(String id) async {
    final box = await _ensureBox();
    final raw = box.get(_normalizeId(id));
    return raw == null ? null : decodeTemplate(raw);
  }

  Future<List<String>> getAllTemplateIds() async {
    final box = await _ensureBox();
    final ids = box.keys.map((key) => key.toString()).toList(growable: false);
    ids.sort();
    return ids;
  }

  Future<bool> containsTemplate(String id) async {
    final box = await _ensureBox();
    return box.containsKey(_normalizeId(id));
  }

  Future<void> renameTemplate(String fromId, String toId) async {
    final sourceId = _normalizeId(fromId);
    final targetId = _normalizeId(toId);
    if (sourceId == targetId) return;

    final box = await _ensureBox();
    final raw = box.get(sourceId);
    if (raw == null) {
      throw StateError('Template "$sourceId" does not exist.');
    }
    if (box.containsKey(targetId)) {
      throw StateError('Template "$targetId" already exists.');
    }

    final template = decodeTemplate(raw)..['id'] = targetId;
    await box.put(targetId, jsonEncode(template));
    await box.delete(sourceId);
  }

  Future<void> duplicateTemplate(String sourceId, String targetId) async {
    final source = _normalizeId(sourceId);
    final target = _normalizeId(targetId);
    final box = await _ensureBox();
    final raw = box.get(source);
    if (raw == null) {
      throw StateError('Template "$source" does not exist.');
    }
    if (box.containsKey(target)) {
      throw StateError('Template "$target" already exists.');
    }

    final template = decodeTemplate(raw)..['id'] = target;
    await box.put(target, jsonEncode(template));
  }

  Future<void> deleteTemplate(String id) async {
    final box = await _ensureBox();
    await box.delete(_normalizeId(id));
  }

  Map<String, dynamic> decodeTemplate(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Report template must be a JSON object.');
    }
    final template = Map<String, dynamic>.from(decoded);
    final version = template['version'];
    if (version != null && version is! num) {
      throw const FormatException('Report template version must be numeric.');
    }
    if (template['paper'] is! Map) {
      throw const FormatException(
          'Report template must contain a paper object.');
    }
    if (template['elements'] is! List) {
      throw const FormatException(
          'Report template must contain an elements list.');
    }
    return template;
  }

  Future<Box<String>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(boxName);
    return _box!;
  }

  String _normalizeId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Template id cannot be empty.');
    }
    return normalized;
  }
}
