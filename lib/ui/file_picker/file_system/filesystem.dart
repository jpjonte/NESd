import 'dart:typed_data';

import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// This won't be called in normal operation, so we ignore it
// coverage:ignore-start
final filesystemProvider = Provider<Filesystem>((ref) {
  throw UnimplementedError();
});
// coverage:ignore-end

abstract class Filesystem {
  Future<List<FilesystemFile>> list(String path);

  Future<Uint8List> read(String path);

  Future<bool> exists(String path);

  Future<bool> isFile(String path);

  Future<bool> isDirectory(String path);

  Future<bool> hasPermission(String path);

  Future<FilesystemFile?> chooseDirectory(String initialDirectory);

  Future<FilesystemFile?> parent(String path);

  Future<FilesystemFile?> getDocumentsDirectory();
}
