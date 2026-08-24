import 'dart:typed_data';

import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

/// Fallback filesystem when persistent storage is unavailable
class MemoryStorageFilesystem implements StorageFilesystem {
  final Map<String, ({Uint8List bytes, DateTime modified})> _files = {};

  @override
  Future<Uint8List?> read(String path) async => _files[path]?.bytes;

  @override
  Future<void> write(String path, Uint8List data) async {
    _files[path] = (bytes: Uint8List.fromList(data), modified: DateTime.now());
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(path);
  }

  @override
  Future<bool> exists(String path) async => _files.containsKey(path);

  @override
  Future<List<String>> list(String directory) async {
    final prefix = directory.endsWith('/') ? directory : '$directory/';

    return _files.keys
        .where(
          (key) =>
              key.startsWith(prefix) &&
              !key.substring(prefix.length).contains('/'),
        )
        .toList();
  }

  // Paths are flat keys, directories exist implicitly. Nothing to create
  @override
  Future<void> createDirectory(String path) async {}

  @override
  Future<DateTime?> lastModified(String path) async => _files[path]?.modified;
}
