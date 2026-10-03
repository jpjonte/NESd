import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_importer.g.dart';

typedef PickFile =
    Future<PlatformFile?> Function({
      required FileType type,
      List<String>? allowedExtensions,
    });

@riverpod
RomImporter romImporter(Ref ref) => kIsWeb
    ? WebRomImporter(storage: ref.watch(storageFilesystemProvider))
    : NativeRomImporter();

abstract interface class RomImporter {
  Future<FilesystemFile?> pickRom();

  Future<FilesystemFile> importDropped(XFile file);
}

class NativeRomImporter implements RomImporter {
  NativeRomImporter({this.pickFile = FilePicker.pickFile});

  final PickFile pickFile;

  @override
  Future<FilesystemFile?> pickRom() async {
    final result = await _pickRomFile(pickFile);
    final path = result?.path;

    if (path == null) {
      return null;
    }

    return _fileAt(path);
  }

  @override
  Future<FilesystemFile> importDropped(XFile file) async => _fileAt(file.path);

  FilesystemFile _fileAt(String path) => FilesystemFile(
    path: path,
    name: p.basename(path),
    type: FilesystemFileType.file,
  );
}

/// Copies the picked bytes into browser storage under [webRomsDirectory].
class WebRomImporter implements RomImporter {
  WebRomImporter({required this.storage, this.pickFile = FilePicker.pickFile});

  final StorageFilesystem storage;
  final PickFile pickFile;

  @override
  Future<FilesystemFile?> pickRom() async {
    final result = await _pickRomFile(pickFile);

    if (result == null) {
      return null;
    }

    return await _store(result.name, await result.readAsBytes());
  }

  @override
  Future<FilesystemFile> importDropped(XFile file) async =>
      await _store(file.name, await file.readAsBytes());

  Future<FilesystemFile> _store(String name, Uint8List bytes) async {
    final path = '$webRomsDirectory/$name';

    await storage.write(path, bytes);

    return FilesystemFile(
      path: path,
      name: name,
      type: FilesystemFileType.file,
    );
  }
}

Future<PlatformFile?> _pickRomFile(PickFile pickFile) =>
    pickFile(type: FileType.custom, allowedExtensions: romFileTypeExtensions);
