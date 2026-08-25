import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

/// Shows the ROM picker and turns the result into a loadable [FilesystemFile].
// ignore: one_member_abstracts
abstract interface class RomImporter {
  Future<FilesystemFile?> pickRom();
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

    return FilesystemFile(
      path: path,
      name: p.basename(path),
      type: FilesystemFileType.file,
    );
  }
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

    final bytes = await result.readAsBytes();
    final path = '$webRomsDirectory/${result.name}';

    await storage.write(path, bytes);

    return FilesystemFile(
      path: path,
      name: result.name,
      type: FilesystemFileType.file,
    );
  }
}

Future<PlatformFile?> _pickRomFile(PickFile pickFile) =>
    pickFile(type: FileType.custom, allowedExtensions: ['nes', 'zip']);
