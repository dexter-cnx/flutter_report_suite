import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EscPosPrinterService hardware capabilities', () {
    test('rejects cut request when no cutter capability is supplied', () async {
      final transport = _FakeTransport();
      final service = EscPosPrinterService();

      await expectLater(
        service.printReceiptWithTransport(
          transport: transport,
          templateJson: _templateJson,
          data: const <String, dynamic>{},
          cutAfterPrint: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );

      expect(transport.sendCalls, 0);
    });

    test('prints before invoking the explicit cutter capability', () async {
      final events = <String>[];
      final transport = _FakeTransport(events: events);
      final cutter = _FakeCutter(events: events);
      final service = EscPosPrinterService();

      await service.printReceiptWithTransport(
        transport: transport,
        templateJson: _templateJson,
        data: const <String, dynamic>{},
        cutAfterPrint: true,
        cutter: cutter,
      );

      expect(events, <String>['send', 'cut']);
      expect(transport.lastBytes, isNotEmpty);
      expect(cutter.cutCalls, 1);
    });

    test('quick receipt rendering contains no implicit cut command', () async {
      final service = EscPosPrinterService();
      final bytes = await service.buildQuickReceipt(
        data: const <String, dynamic>{
          'shop': <String, dynamic>{'name': 'ร้านค้า'},
          'total': 100,
        },
        encodingConfig: const EscPosEncodingConfig.cp874(codeTable: 30),
      );

      expect(_containsSequence(bytes, const <int>[0x1D, 0x56]), isFalse);
    });
  });
}

const Map<String, dynamic> _templateJson = <String, dynamic>{
  'id': 'capability-test',
  'version': 1,
  'paper': <String, dynamic>{
    'type': 'thermal',
    'widthMm': 80,
    'autoHeight': true,
  },
  'elements': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'title',
      'type': 'text',
      'key': 'Receipt',
      'x': 0,
      'y': 0,
      'w': 70,
      'h': 10,
    },
  ],
};

class _FakeTransport implements EscPosTransport {
  _FakeTransport({this.events});

  final List<String>? events;
  int sendCalls = 0;
  List<int> lastBytes = const <int>[];

  @override
  Future<void> send(List<int> bytes) async {
    sendCalls++;
    lastBytes = List<int>.from(bytes);
    events?.add('send');
  }
}

class _FakeCutter implements CutterCapability {
  _FakeCutter({this.events});

  final List<String>? events;
  int cutCalls = 0;

  @override
  Future<void> cutPaper() async {
    cutCalls++;
    events?.add('cut');
  }
}

bool _containsSequence(List<int> source, List<int> sequence) {
  for (var index = 0; index <= source.length - sequence.length; index++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (source[index + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
