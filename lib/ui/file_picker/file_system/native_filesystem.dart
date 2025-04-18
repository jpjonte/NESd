import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class NativeFilesystem extends Filesystem {
  @override
  Future<List<FilesystemFile>> list(String path) async {
    final files =
        Directory(path)
            .listSync()
            .map(
              (e) => FilesystemFile(
                path: e.path,
                name: p.basename(e.path),
                type: switch (e) {
                  File() => FilesystemFileType.file,
                  Directory() || Link() => FilesystemFileType.directory,
                  _ => throw UnimplementedError(),
                },
              ),
            )
            .toList();

    return files;
  }

  @override
  Future<Uint8List> read(String path) async {
    return await File(path).readAsBytes();
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
  Future<FilesystemFile?> chooseDirectory(String initialDirectory) async {
    final result = await FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
    );

    if (result == null) {
      return null;
    }

    return FilesystemFile(
      path: result,
      name: result,
      type: FilesystemFileType.directory,
    );
  }

  @override
  Future<bool> hasPermission(String path) async {
    return true;
  }

  @override
  Future<FilesystemFile?> parent(String path) async {
    final parentPath = Directory(path).parent.path;

    return FilesystemFile(
      path: parentPath,
      name: parentPath,
      type: FilesystemFileType.directory,
    );
  }

  @override
  Future<FilesystemFile> getDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();

    return FilesystemFile(
      path: directory.path,
      name: directory.path,
      type: FilesystemFileType.directory,
    );
  }
}
