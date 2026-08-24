import 'dart:typed_data';

import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:path/path.dart' as p;

class WebFilesystem extends Filesystem {
  WebFilesystem({required this.storage});

  final StorageFilesystem storage;

  @override
  Future<List<FilesystemFile>> list(String path) async {
    final entries = await storage.list(path);

    return entries
        .map(
          (entry) => FilesystemFile(
            path: entry,
            name: p.basename(entry),
            type: FilesystemFileType.file,
          ),
        )
        .toList();
  }

  @override
  Future<Uint8List> read(String path) async {
    final data = await storage.read(path);

    if (data == null) {
      throw FileNotFound(path: path);
    }

    return data;
  }

  @override
  Future<bool> exists(String path) => storage.exists(path);

  @override
  Future<bool> isFile(String path) => storage.exists(path);

  @override
  Future<bool> isDirectory(String path) async => false;

  @override
  Future<bool> hasPermission(String path) async => true;

  @override
  Future<FilesystemFile?> chooseDirectory(String initialDirectory) async =>
      null;

  @override
  Future<FilesystemFile?> parent(String path) async => null;

  @override
  Future<FilesystemFile?> getDocumentsDirectory() async => null;
}
