import 'unified_printer.dart';

abstract interface class PrinterDiscoverySource {
  Future<List<UnifiedPrinter>> discover();
}
