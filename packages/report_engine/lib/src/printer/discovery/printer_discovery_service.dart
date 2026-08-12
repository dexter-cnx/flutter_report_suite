import 'printer_discovery_source.dart';
import 'unified_printer.dart';

class PrinterDiscoveryService {
  const PrinterDiscoveryService({required List<PrinterDiscoverySource> sources})
      : _sources = sources;

  final List<PrinterDiscoverySource> _sources;

  Future<List<UnifiedPrinter>> discoverAll() async {
    final byId = <String, UnifiedPrinter>{};

    for (final source in _sources) {
      try {
        final printers = await source.discover();
        for (final printer in printers) {
          if (printer.id.trim().isEmpty) continue;
          byId.putIfAbsent(printer.id, () => printer);
        }
      } catch (_) {
        // A platform/plugin failure in one mechanism must not suppress printers
        // discovered by the remaining mechanisms.
      }
    }

    final printers = byId.values.toList(growable: false)
      ..sort((left, right) {
        final typeOrder = left.type.index.compareTo(right.type.index);
        if (typeOrder != 0) return typeOrder;
        final nameOrder = left.name.toLowerCase().compareTo(
              right.name.toLowerCase(),
            );
        if (nameOrder != 0) return nameOrder;
        return left.id.compareTo(right.id);
      });
    return List<UnifiedPrinter>.unmodifiable(printers);
  }
}
