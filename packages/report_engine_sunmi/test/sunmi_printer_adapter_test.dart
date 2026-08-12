import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';
import 'package:report_engine_sunmi/report_engine_sunmi.dart';

void main() {
  group('SunmiPrinterAdapter', () {
    test('defaults to print-only capabilities', () async {
      final adapter = SunmiPrinterAdapter(bridge: _FakeBridge());
      final printers = await adapter.discover();

      expect(adapter, isNot(isA<CutterCapability>()));
      expect(adapter, isNot(isA<CashDrawerCapability>()));
      expect(printers.single.metadata['cutter'], 'false');
      expect(printers.single.metadata['cashDrawer'], 'false');
    });

    test('exposes only capabilities selected by verified hardware profile', () {
      final cutterOnly = SunmiPrinterAdapter(
        bridge: _FakeBridge(),
        hardwareProfile: const SunmiHardwareProfile(supportsCutter: true),
      );
      final drawerOnly = SunmiPrinterAdapter(
        bridge: _FakeBridge(),
        hardwareProfile: const SunmiHardwareProfile(supportsCashDrawer: true),
      );

      expect(cutterOnly, isA<CutterCapability>());
      expect(cutterOnly, isNot(isA<CashDrawerCapability>()));
      expect(drawerOnly, isNot(isA<CutterCapability>()));
      expect(drawerOnly, isA<CashDrawerCapability>());
    });

    test('delegates enabled cutter and drawer operations', () async {
      final bridge = _FakeBridge();
      final adapter = SunmiPrinterAdapter(
        bridge: bridge,
        hardwareProfile: const SunmiHardwareProfile(
          supportsCutter: true,
          supportsCashDrawer: true,
        ),
      );

      await (adapter as CutterCapability).cutPaper();
      await (adapter as CashDrawerCapability).openCashDrawer();
      final isOpen = await (adapter as CashDrawerCapability).isCashDrawerOpen();
      final rebound = await adapter.rebindPrinter();

      expect(bridge.cutCalls, 1);
      expect(bridge.drawerCalls, 1);
      expect(bridge.rebindCalls, 1);
      expect(isOpen, isTrue);
      expect(rebound, isTrue);
    });

    test('sends raw ESC/POS bytes through the bridge', () async {
      final bridge = _FakeBridge();
      final adapter = SunmiPrinterAdapter(bridge: bridge);

      await adapter.send(<int>[0x1B, 0x40, 0x0A]);

      expect(bridge.lastBytes, <int>[0x1B, 0x40, 0x0A]);
    });
  });
}

class _FakeBridge implements SunmiPrinterBridge {
  List<int>? lastBytes;
  int cutCalls = 0;
  int drawerCalls = 0;
  int rebindCalls = 0;

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

  @override
  Future<bool> rebindPrinter() async {
    rebindCalls++;
    return true;
  }
}
