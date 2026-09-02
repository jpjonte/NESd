import 'package:flutter/foundation.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/exception/invalid_archive.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/seven_zip_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:path/path.dart' as p;

@immutable
class ArchiveEntryInfo {
  const ArchiveEntryInfo({required this.name, required this.isDirectory});

  final String name;
  final bool isDirectory;
}

abstract class ArchiveFilesystem extends Filesystem {
  ArchiveFilesystem({required this.path});

  static Future<ArchiveFilesystem> open({
    required String path,
    required Uint8List data,
  }) async {
    if (isZipFile(path)) {
      return ZipFilesystem(path: path, zipData: data);
    }

    if (isSevenZipFile(path)) {
      return SevenZipFilesystem.open(path: path, data: data);
    }

    throw UnsupportedFileType(fileExtension(path));
  }

  final String path;

  List<ArchiveEntryInfo> get entries;

  Future<Uint8List> readEntry(String name);

  ArchiveEntryInfo? _entry(String name) {
    for (final entry in entries) {
      if (entry.name == name) {
        return entry;
      }
    }

    return null;
  }

  @override
  Future<List<FilesystemFile>> list(String path) async => [
    for (final entry in entries)
      FilesystemFile(
        path: '${this.path}$archiveSeparator${entry.name}',
        name: entry.name,
        type: FilesystemFileType.file,
      ),
  ];

  @override
  Future<Uint8List> read(String path) => readEntry(path);

  @override
  Future<bool> exists(String path) async => _entry(path) != null;

  @override
  Future<bool> isFile(String path) async => _entry(path)?.isDirectory == false;

  @override
  Future<bool> isDirectory(String path) async =>
      _entry(path)?.isDirectory ?? false;

  @override
  Future<bool> hasPermission(String path) async => true;

  @override
  Future<FilesystemFile?> parent(String path) async {
    final parentPath = p.dirname(path);

    return FilesystemFile(
      path: parentPath,
      name: parentPath,
      type: FilesystemFileType.directory,
    );
  }

  @override
  Future<FilesystemFile?> chooseDirectory(String initialDirectory) async =>
      null;

  @override
  Future<FilesystemFile> getDocumentsDirectory() => throw UnimplementedError();
}
