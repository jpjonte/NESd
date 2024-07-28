import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';

class NativeFileSystem extends FileSystem {
  @override
  Future<(String, List<String>)> list(String path) async {
    return (path, Directory(path).listSync().map((e) => e.path).toList());
  }

  @override
  Future<Uint8List> read(String path) async {
    return File(path).readAsBytes();
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).existsSync();
  }

  @override
  Future<String?> chooseDirectory(String initialDirectory) async {
    return FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
    );
  }
}
