import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

class GatedStorage implements StorageFilesystem {
  GatedStorage(this.inner, {this.gateThumbnails = true});

  final StorageFilesystem inner;

  final bool gateThumbnails;

  final _gate = Completer<void>();

  final List<String> reads = [];

  void openGate() => _gate.complete();

  int readsMatching(Pattern pattern) =>
      reads.where((path) => path.contains(pattern)).length;

  @override
  Future<Uint8List?> read(String path) async {
    reads.add(path);

    if (gateThumbnails && path.endsWith('.png')) {
      await _gate.future;
    }

    return inner.read(path);
  }

  @override
  Future<void> write(String path, Uint8List data) => inner.write(path, data);

  @override
  Future<void> delete(String path) => inner.delete(path);

  @override
  Future<bool> exists(String path) => inner.exists(path);

  @override
  Future<List<String>> list(String directory) => inner.list(directory);

  @override
  Future<void> createDirectory(String path) => inner.createDirectory(path);

  @override
  Future<DateTime?> lastModified(String path) => inner.lastModified(path);
}
