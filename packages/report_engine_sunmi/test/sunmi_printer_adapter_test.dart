import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';
import 'package:report_engine_sunmi/report_engine_sunmi.dart';

void main() {
  group('SunmiPrinterAdapter', () {
    test('sends raw ESC/POS bytes through the bridge', () async {
      final bridge = _FakeBridge();
      final adapter = SunmiPrinterAdapter(bridge: bridge);

      await adapter.send(<int>[0x1B, 0x40, 0x0A]);

      expect(bridge.lastBytes, <int>[0x1B, 0x40, 0x0A]);
    });

    test('discovers embedded Sunmi without exposing plugin objects', () async {
      final adapter = SunmiPrinterAdapter(bridge: _FakeBridge());

      final printers = await adapter.discover();

      expect(printers, hasLength(1));
      expect(printers.single.id, 'embedded:sunmi:SN-001');
      expect(printers.single.name, 'Sunmi V2_PRO');
      expect(printers.single.type, PrinterConnectionType.embedded);
      expect(printers.single.metadata['version'], '1.2.3');
    });

    test('delegates cut and cash drawer operations', () async {
      final bridge = _FakeBridge();
      final adapter = SunmiPrinterAdapter(bridge: bridge);

      await adapter.cutPaper();
      await adapter.openCashDrawer();
      final isOpen = await adapter.isCashDrawerOpen();

      expect(bridge.cutCalls, 1);
      expect(bridge.drawerCalls, 1);
      expect(isOpen, isTrue);
    });
  });
}

class _FakeBridge implements SunmiPrinterBridge {
  List<int>? lastBytes;
  int cutCalls = 0;
  int drawerCalls = 0;

  @override
  Future<String?> printEscPos(List<int> bytes) async {
    lastBytes = List<int>.from(bytes);
    return 'ok';
  }

  @override
  Future<String?> cutPaper() async {
    cutCalls++;
    return 'ok';
  }

  @override
  Future<String?> openDrawer() async {
    drawerCalls++;
    return 'ok';
  }

  @override
  Future<bool> isDrawerOpen() async => true;

  @override
  Future<String?> getId() async => 'SN-001';

  @override
  Future<String?> getType() async => 'V2_PRO';

  @override
  Future<String?> getVersion() async => '1.2.3';
}
