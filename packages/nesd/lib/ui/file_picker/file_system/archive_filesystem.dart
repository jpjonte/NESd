import 'package:flutter/foundation.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/seven_zip_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:path/path.dart' as p;

FilesystemFile? archiveParent(String path) {
  final split = splitArchivePath(path);

  if (split == null) {
    return null;
  }

  final separator = split.entryPath.lastIndexOf(entryPathSeparator);

  if (separator == -1) {
    return FilesystemFile(
      path: split.archivePath,
      name: p.basename(split.archivePath),
      type: FilesystemFileType.file,
    );
  }

  final parentPath = split.entryPath.substring(0, separator);

  return FilesystemFile(
    path: '${split.archivePath}$archiveSeparator$parentPath',
    name: parentPath.substring(parentPath.lastIndexOf(entryPathSeparator) + 1),
    type: FilesystemFileType.directory,
  );
}

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

  String _prefixFor(String path) {
    if (path == this.path) {
      return '';
    }

    final split = splitArchivePath(path);

    if (split == null ||
        split.archivePath != this.path ||
        split.entryPath.isEmpty) {
      return '';
    }

    return '${split.entryPath}$entryPathSeparator';
  }

  @override
  Future<List<FilesystemFile>> list(String path) async {
    final prefix = _prefixFor(path);
    final children = <String, bool>{};

    for (final entry in entries) {
      if (!entry.name.startsWith(prefix)) {
        continue;
      }

      final remainder = entry.name.substring(prefix.length);

      if (remainder.isEmpty) {
        continue;
      }

      final separator = remainder.indexOf(entryPathSeparator);
      final name = separator == -1
          ? remainder
          : remainder.substring(0, separator);
      final isDirectory = separator != -1 || entry.isDirectory;

      children[name] = (children[name] ?? false) || isDirectory;
    }

    return [
      for (final MapEntry(key: name, value: isDirectory) in children.entries)
        FilesystemFile(
          path: '${this.path}$archiveSeparator$prefix$name',
          name: name,
          type: isDirectory
              ? FilesystemFileType.directory
              : FilesystemFileType.file,
        ),
    ];
  }

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
