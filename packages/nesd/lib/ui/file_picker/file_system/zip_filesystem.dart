import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class ZipFilesystem extends Filesystem {
  ZipFilesystem({required this.path, required Uint8List zipData})
    : archive = ZipDecoder().decodeBytes(zipData);

  final String path;
  final Archive archive;

  @override
  Future<FilesystemFile?> chooseDirectory(String initialDirectory) async {
    return null;
  }

  @override
  Future<bool> exists(String path) async {
    return archive.files.any((file) => file.name == path);
  }

  @override
  Future<bool> isDirectory(String path) async {
    return archive.files.any((file) => file.name == path && !file.isFile);
  }

  @override
  Future<bool> isFile(String path) async {
    return archive.files.any((file) => file.name == path && file.isFile);
  }

  @override
  Future<List<FilesystemFile>> list(String path) async {
    final files = archive.files.map(
      (file) => FilesystemFile(
        path: '${this.path}:${file.name}',
        name: file.name,
        type: FilesystemFileType.file,
      ),
    );

    return files.toList();
  }

  @override
  Future<Uint8List> read(String path) async {
    final file = archive.files.firstWhereOrNull((file) => file.name == path);

    if (file == null) {
      throw FileNotFound(path: path);
    }

    return Uint8List.fromList(file.content as List<int>);
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
  Future<FilesystemFile> getDocumentsDirectory() {
    throw UnimplementedError();
  }
}
