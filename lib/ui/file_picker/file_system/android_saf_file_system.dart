import 'dart:io';
import 'dart:typed_data';

import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:saf/saf.dart';

class AndroidSafFileSystem extends FileSystem {
  @override
  Future<(String, List<String>)> list(String path) async {
    final saf = Saf(_fixPath(path));

    final isGranted = await saf.getDirectoryPermission(
      grantWritePermission: false,
      isDynamic: true,
    );

    if (isGranted != null && isGranted) {
      return (saf.currentDirectory ?? path, (await saf.getFilesPath()) ?? []);
    } else {
      throw Exception('Permission denied: $isGranted');
    }
  }

  @override
  Future<Uint8List> read(String path) async {
    final saf = Saf(path);

    final cached = await saf.singleCache(filePath: _fixPath(path));

    if (cached == null) {
      throw Exception('File not found: $path');
    }

    return File(cached).readAsBytes();
  }

  @override
  Future<bool> exists(String path) async {
    return (await Saf.exists(_fixPath(path))) ?? false;
  }

  @override
  Future<String?> chooseDirectory(String initialDirectory) async {
    return Saf.getDynamicDirectoryPermission(grantWritePermission: false);
  }

  // dirty hack to fix paths before passing them to the SAF plugin
  // hopefully temporary
  String _fixPath(String path) {
    return path.replaceFirst('/storage/emulated/0/', '');
  }
}
