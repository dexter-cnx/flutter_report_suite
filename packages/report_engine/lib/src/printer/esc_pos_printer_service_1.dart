
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// ESC/POS Direct Printer - พิมพ์ตรง ไม่ผ่าน PDF เร็ว x3 สำหรับเครื่องความร้อน
class EscPosPrinterService {
  
  /// Scan หาเครื่อง Bluetooth
  Future<List<ScanResult>> scanPrinters({Duration timeout = const Duration(seconds: 5)}) async {
    List<ScanResult> results = [];
    await FlutterBluePlus.startScan(timeout: timeout);
    FlutterBluePlus.scanResults.listen((r) {
      results = r;
    });
    await Future.delayed(timeout);
    await FlutterBluePlus.stopScan();
    return results;
  }

  /// Connect และพิมพ์ด้วย template เดิม แต่ render เป็น ESC/POS commands
  Future<void> printReceipt({
    required BluetoothDevice device,
    required Map<String, dynamic> templateJson,
    required Map<String, dynamic> data,
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (_) {}
    
    // Find printer service
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? writeChar;
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.write) {
          writeChar = c;
          break;
        }
      }
    }
    if (writeChar == null) throw Exception('No writable characteristic found');

    // Generate ESC/POS bytes
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Resolve helper
    dynamic resolve(String? key) {
      if (key == null) return '';
      String k = key.replaceAll('{{','').replaceAll('}}','').trim();
      var parts = k.split('.');
      dynamic cur = data;
      for (var p in parts) {
        if (cur is Map && cur.containsKey(p)) cur = cur[p];
        else return '';
      }
      return cur ?? '';
    }

    final elements = (templateJson['elements'] as List);
    for (var el in elements) {
      final type = el['type'];
      final raw = resolve(el['key']).toString();
      final style = el['style'] ?? {};
      final isBold = style['bold'] == true;
      final align = style['align'];

      if (align == 'center') bytes += generator.text(raw, styles: PosStyles(align: PosAlign.center, bold: isBold, fontType: PosFontType.fontA));
      else if (align == 'right') bytes += generator.text(raw, styles: PosStyles(align: PosAlign.right, bold: isBold));
      else {
        if (type == 'line') bytes += generator.hr();
        else if (type == 'qrcode') bytes += generator.qrcode(raw);
        else if (type == 'barcode') bytes += generator.barcode(Barcode.code128(raw));
        else if (type == 'table' && resolve(el['key']) is List) {
          // Simple table render
          List list = resolve(el['key']);
          for (var row in list) {
            if (row is Map) {
              // Example: name - price
              String line = "\${row.values.first}  \${row.values.last}";
              bytes += generator.text(line, styles: const PosStyles());
            }
          }
        } else {
          if (raw.isNotEmpty) bytes += generator.text(raw, styles: PosStyles(bold: isBold));
        }
      }
    }

    bytes += generator.cut();

    // Chunk write (BLE limit 180 bytes)
    const chunkSize = 180;
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      await writeChar.write(Uint8List.fromList(bytes.sublist(i, end)), withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await device.disconnect();
  }

  /// Helper สร้างใบเสร็จแบบไม่ต้องใช้ template (quick print)
  Future<List<int>> buildQuickReceipt({
    required Map<String, dynamic> data,
    PaperSize paper = PaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paper, profile);
    List<int> bytes = [];
    bytes += gen.text(data['shop']?['name'] ?? 'ร้านค้า', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += gen.text('สาขา \${data['shop']?['branch'] ?? ''}', styles: const PosStyles(align: PosAlign.center));
    bytes += gen.hr();
    bytes += gen.text('วันที่ \${data['date'] ?? ''}');
    bytes += gen.text('เลขที่ \${data['orderId'] ?? ''}');
    bytes += gen.hr();
    if (data['items'] is List) {
      for (var item in data['items']) {
        bytes += gen.row([
          PosColumn(text: item['name'].toString(), width: 8),
          PosColumn(text: 'x\${item['qty']}', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '\${item['price']}', width: 2, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }
    bytes += gen.hr();
    bytes += gen.text('รวม \${data['total'] ?? ''} บาท', styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2));
    bytes += gen.qrcode(data['orderId']?.toString() ?? 'test');
    bytes += gen.text(data['note'] ?? 'ขอบคุณครับ', styles: const PosStyles(align: PosAlign.center));
    bytes += gen.cut();
    return bytes;
  }
}
