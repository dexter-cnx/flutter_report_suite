import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> exportTemplateJsonFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'Export Template JSON',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['json'],
    bytes: bytes,
  );
  return result != null;
}
