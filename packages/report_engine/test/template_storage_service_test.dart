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
    tempDir =
        await Directory.systemTemp.createTemp('report-engine-storage-test-');
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

  test('save normalizes storage key and payload id', () async {
    await storage.saveTemplate('  renamed  ', template);

    final saved = await storage.getTemplate('renamed');
    expect(saved?['id'], 'renamed');
    expect(saved?['version'], 1);
  });

  test('rename updates both storage key and JSON payload id', () async {
    await storage.saveTemplate('receipt', template);
    await storage.renameTemplate('receipt', 'receipt-copy');

    expect(await storage.getTemplate('receipt'), isNull);
    final renamed = await storage.getTemplate('receipt-copy');
    expect(renamed?['id'], 'receipt-copy');
    expect(renamed?['paper'], template['paper']);
    expect(renamed?['elements'], template['elements']);
  });

  test('duplicate preserves source and assigns target payload id', () async {
    await storage.saveTemplate('receipt', template);
    await storage.duplicateTemplate('receipt', 'receipt-copy');

    expect((await storage.getTemplate('receipt'))?['id'], 'receipt');
    final copy = await storage.getTemplate('receipt-copy');
    expect(copy?['id'], 'receipt-copy');
    expect(copy?['paper'], template['paper']);
    expect(copy?['elements'], template['elements']);
  });

  test('rejects duplicate rename and duplicate targets', () async {
    await storage.saveTemplate('first', template);
    await storage.saveTemplate('second', template);

    await expectLater(
      storage.renameTemplate('first', 'second'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      storage.duplicateTemplate('first', 'second'),
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

  test('rejects invalid template before saving', () async {
    await expectLater(
      storage.saveTemplate(
        'bad',
        const <String, dynamic>{'id': 'bad', 'version': 1},
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await storage.containsTemplate('bad'), isFalse);
  });
}
