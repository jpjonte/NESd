import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const webStorageRoot = '/nesd';

const webRomsDirectory = '$webStorageRoot/roms';

// Overridden in main.dart with the platform implementation.
// coverage:ignore-start
final storageFilesystemProvider = Provider<StorageFilesystem>((ref) {
  throw UnimplementedError();
});
// coverage:ignore-end

/// Key-value storage for app data (saves, states, thumbnails, imported
/// ROMs).
abstract class StorageFilesystem {
  Future<Uint8List?> read(String path);

  /// Atomic and creates parent directories as needed
  Future<void> write(String path, Uint8List data);

  Future<void> delete(String path);

  Future<bool> exists(String path);

  /// Returns the full paths of a directory's direct children only
  Future<List<String>> list(String directory);

  Future<void> createDirectory(String path);

  Future<DateTime?> lastModified(String path);
}
