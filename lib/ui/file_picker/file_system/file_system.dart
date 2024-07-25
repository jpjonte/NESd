import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

final fileSystemProvider = Provider<FileSystem>((ref) {
  throw UnimplementedError();
});

abstract class FileSystem {
  Future<(String, List<String>)> list(String path);

  Future<Uint8List> read(String path);

  Future<bool> exists(String path);

  Future<String?> chooseDirectory(String initialDirectory);
}
