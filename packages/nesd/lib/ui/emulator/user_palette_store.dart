import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:path/path.dart' as p;

const userPaletteExtension = '.pal';

class UserPaletteStore {
  const UserPaletteStore({required this.storage, required this.directory});

  final StorageFilesystem storage;

  final String directory;

  Future<List<String>> list() async {
    final paths = await storage.list(directory);

    return [
      for (final path in paths)
        if (fileExtension(path) == userPaletteExtension)
          p.basenameWithoutExtension(path),
    ]..sort(compareAsciiLowerCase);
  }

  Future<Uint8List?> read(String name) => storage.read(_path(name));

  Future<void> write(String name, Uint8List bytes) =>
      storage.write(_path(name), bytes);

  Future<void> delete(String name) => storage.delete(_path(name));

  String _path(String name) => p.join(directory, '$name$userPaletteExtension');
}
