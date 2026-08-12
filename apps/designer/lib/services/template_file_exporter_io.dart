import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> exportTemplateJsonFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Template JSON',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    return result != null;
  }

  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Export Template JSON',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  if (path == null) return false;
  await File(path).writeAsBytes(bytes, flush: true);
  return true;
}
