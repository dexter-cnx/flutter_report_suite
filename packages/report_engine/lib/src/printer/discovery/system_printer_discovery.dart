import 'package:printing/printing.dart';

import 'printer_discovery_source.dart';
import 'unified_printer.dart';

class SystemPrinterDiscovery implements PrinterDiscoverySource {
  const SystemPrinterDiscovery();

  @override
  Future<List<UnifiedPrinter>> discover() async {
    final printers = await Printing.listPrinters();
    return printers
        .map(
          (printer) => UnifiedPrinter(
            id: 'system:${printer.url}',
            name: printer.name,
            type: PrinterConnectionType.system,
            metadata: <String, String>{
              'url': printer.url,
              if (printer.model != null) 'model': printer.model!,
              if (printer.location != null) 'location': printer.location!,
              'isDefault': printer.isDefault.toString(),
              'isAvailable': printer.isAvailable.toString(),
            },
          ),
        )
        .toList(growable: false);
  }
}
