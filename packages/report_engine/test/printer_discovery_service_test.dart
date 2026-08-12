import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  group('PrinterDiscoveryService', () {
    test('combines sources and returns deterministic ordering', () async {
      final service = PrinterDiscoveryService(
        sources: <PrinterDiscoverySource>[
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: 'bluetooth:b',
              name: 'Beta',
              type: PrinterConnectionType.bluetooth,
            ),
          ]),
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: 'system:a',
              name: 'Alpha',
              type: PrinterConnectionType.system,
            ),
          ]),
        ],
      );

      final result = await service.discoverAll();

      expect(result.map((printer) => printer.id),
          <String>['system:a', 'bluetooth:b']);
    });

    test('deduplicates by deterministic id', () async {
      final service = PrinterDiscoveryService(
        sources: <PrinterDiscoverySource>[
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: 'system:printer-1',
              name: 'Primary',
              type: PrinterConnectionType.system,
            ),
          ]),
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: 'system:printer-1',
              name: 'Duplicate',
              type: PrinterConnectionType.system,
            ),
          ]),
        ],
      );

      final result = await service.discoverAll();

      expect(result, hasLength(1));
      expect(result.single.name, 'Primary');
    });

    test('isolates source failures', () async {
      final service = PrinterDiscoveryService(
        sources: <PrinterDiscoverySource>[
          const _ThrowingSource(),
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: 'system:ok',
              name: 'Working printer',
              type: PrinterConnectionType.system,
            ),
          ]),
        ],
      );

      final result = await service.discoverAll();

      expect(result.map((printer) => printer.id), <String>['system:ok']);
    });

    test('ignores printers without an id', () async {
      final service = PrinterDiscoveryService(
        sources: <PrinterDiscoverySource>[
          _FakeSource(<UnifiedPrinter>[
            const UnifiedPrinter(
              id: '   ',
              name: 'Invalid',
              type: PrinterConnectionType.network,
            ),
          ]),
        ],
      );

      expect(await service.discoverAll(), isEmpty);
    });
  });
}

class _FakeSource implements PrinterDiscoverySource {
  const _FakeSource(this.printers);

  final List<UnifiedPrinter> printers;

  @override
  Future<List<UnifiedPrinter>> discover() async => printers;
}

class _ThrowingSource implements PrinterDiscoverySource {
  const _ThrowingSource();

  @override
  Future<List<UnifiedPrinter>> discover() async {
    throw StateError('unsupported');
  }
}
