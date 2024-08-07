import 'dart:typed_data';

import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final fileSystemProvider = Provider<FileSystem>((ref) {
  throw UnimplementedError();
});

abstract class FileSystem {
  Future<(String, List<FileSystemFile>)> list(String path);

  Future<Uint8List> read(String path);

  Future<bool> exists(String path);

  Future<bool> isFile(String path);

  Future<bool> isDirectory(String path);

  Future<String?> chooseDirectory(String initialDirectory);
}
