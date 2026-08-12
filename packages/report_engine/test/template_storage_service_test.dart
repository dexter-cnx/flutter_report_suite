import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  late Directory tempDir;
  late TemplateStorageService storage;

  const template = <String, dynamic>{
    'id': 'receipt',
    'version': 1,
    'paper': {
      'type': 'thermal',
      'widthMm': 80,
      'heightMm': 200,
      'autoHeight': true,
      'marginMm': 3,
    },
    'elements': <Map<String, dynamic>>[],
  };

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report-engine-storage-test-');
    Hive.init(tempDir.path);
    storage = TemplateStorageService(boxName: 'templates_test');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves, reads, lists, and deletes templates', () async {
    await storage.saveTemplate('receipt', template);

    expect(await storage.containsTemplate('receipt'), isTrue);
    expect(await storage.getTemplate('receipt'), template);
    expect(await storage.getAllTemplateIds(), ['receipt']);

    await storage.deleteTemplate('receipt');
    expect(await storage.containsTemplate('receipt'), isFalse);
    expect(await storage.getTemplate('receipt'), isNull);
  });

  test('renames a template without changing its JSON payload', () async {
    await storage.saveTemplate('receipt', template);
    await storage.renameTemplate('receipt', 'receipt-copy');

    expect(await storage.getTemplate('receipt'), isNull);
    expect(await storage.getTemplate('receipt-copy'), template);
  });

  test('duplicates a template and preserves the source', () async {
    await storage.saveTemplate('receipt', template);
    await storage.duplicateTemplate('receipt', 'receipt-copy');

    expect(await storage.getTemplate('receipt'), template);
    expect(await storage.getTemplate('receipt-copy'), template);
  });

  test('rejects duplicate rename and duplicate targets', () async {
    await storage.saveTemplate('first', template);
    await storage.saveTemplate('second', template);

    expect(
      () => storage.renameTemplate('first', 'second'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => storage.duplicateTemplate('first', 'second'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects malformed and incompatible template JSON', () {
    expect(
      () => storage.decodeTemplate('[]'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => storage.decodeTemplate('{"version":1,"elements":[]}'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => storage.decodeTemplate(
        '{"version":"one","paper":{},"elements":[]}',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
