import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';

class ZipFileSystem extends FileSystem {
  ZipFileSystem({required this.path, required Uint8List zipData})
      : archive = ZipDecoder().decodeBytes(zipData);

  final String path;
  final Archive archive;

  @override
  Future<String?> chooseDirectory(String initialDirectory) async {
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
  Future<(String, List<FileSystemFile>)> list(String path) async {
    final files = archive.files.map(
      (file) => FileSystemFile(
        path: '${this.path}:${file.name}',
        type: FileSystemFileType.file,
      ),
    );

    return (path, files.toList());
  }

  @override
  Future<Uint8List> read(String path) async {
    final file = archive.files.firstWhere((file) => file.name == path);

    // TODO handle non-file

    return Uint8List.fromList(file.content as List<int>);
  }
}
