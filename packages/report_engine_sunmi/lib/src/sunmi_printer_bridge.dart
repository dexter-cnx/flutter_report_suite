import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

abstract interface class SunmiPrinterBridge {
  Future<String?> printEscPos(List<int> bytes);
  Future<String?> cutPaper();
  Future<String?> openDrawer();
  Future<bool> isDrawerOpen();
  Future<String?> getId();
  Future<String?> getType();
  Future<String?> getVersion();
  Future<bool> rebindPrinter();
}

class PluginSunmiPrinterBridge implements SunmiPrinterBridge {
  PluginSunmiPrinterBridge({SunmiPrinterPlus? printer})
      : _printer = printer ?? SunmiPrinterPlus();

  final SunmiPrinterPlus _printer;

  @override
  Future<String?> printEscPos(List<int> bytes) => _printer.printEscPos(bytes);

  @override
  Future<String?> cutPaper() => _printer.cutPaper();

  @override
  Future<String?> openDrawer() => _printer.openDrawer();

  @override
  Future<bool> isDrawerOpen() => _printer.isDrawerOpen();

  @override
  Future<String?> getId() => _printer.getId();

  @override
  Future<String?> getType() => _printer.getType();

  @override
  Future<String?> getVersion() => _printer.getVersion();

  @override
  Future<bool> rebindPrinter() => _printer.rebindPrinter();
}
