import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Thin wrapper over `file_picker` for importing a price series from a text
/// file. IO only — the returned text is parsed by [TextInputParser] elsewhere.
class FileImportService {
  const FileImportService();

  /// Opens a picker for `.csv` / `.txt` files and returns the file's text, or
  /// `null` if the user cancels or the file has no readable bytes.
  Future<String?> pickTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }
}
