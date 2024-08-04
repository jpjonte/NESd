import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';

class NativeFileSystem extends FileSystem {
  @override
  Future<(String, List<FileSystemFile>)> list(String path) async {
    final files = Directory(path)
        .listSync()
        .map(
          (e) => FileSystemFile(
            path: e.path,
            type: switch (e) {
              File() => FileSystemFileType.file,
              Directory() => FileSystemFileType.directory,
              _ => throw UnimplementedError(),
            },
          ),
        )
        .toList();

    return (path, files);
  }

  @override
  Future<Uint8List> read(String path) async {
    return File(path).readAsBytes();
  }

  @override
  Future<bool> exists(String path) async {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }

  @override
  Future<bool> isFile(String path) async {
    return File(path).existsSync();
  }

  @override
  Future<bool> isDirectory(String path) async {
    return Directory(path).existsSync();
  }

  @override
  Future<String?> chooseDirectory(String initialDirectory) async {
    return FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
    );
  }
}
