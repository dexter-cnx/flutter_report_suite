
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TemplateStorageService {
  static const String boxName = 'report_templates';
  
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Map<String, dynamic>> loadFromAssets(String assetPath) async {
    final str = await rootBundle.loadString(assetPath);
    return jsonDecode(str);
  }

  Future<void> saveTemplate(String id, Map<String, dynamic> json) async {
    var box = await Hive.openBox(boxName);
    await box.put(id, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> getTemplate(String id) async {
    var box = await Hive.openBox(boxName);
    var raw = box.get(id);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<List<String>> getAllTemplateIds() async {
    var box = await Hive.openBox(boxName);
    return box.keys.cast<String>().toList();
  }
}
