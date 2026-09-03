import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:koni_archive_core/koni_archive_core.dart';
import 'package:koni_sevenz/koni_sevenz.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/exception/invalid_archive.dart';
import 'package:nesd/ui/file_picker/file_system/archive_filesystem.dart';

class SevenZipFilesystem extends ArchiveFilesystem {
  SevenZipFilesystem._(this._reader, {required super.path});

  static Future<SevenZipFilesystem> open({
    required String path,
    required Uint8List data,
  }) async {
    try {
      final reader = await const SevenZFormat().openReader(
        MemoryByteSource(data, name: path),
        const ArchiveReadOptions(),
      );

      return SevenZipFilesystem._(reader, path: path);
    } on ArchiveException catch (e) {
      throw InvalidArchive(path, reason: e.message, previous: e);
    }
  }

  final ArchiveReader _reader;

  @override
  late final List<ArchiveEntryInfo> entries = [
    for (final entry in _reader.entries)
      ArchiveEntryInfo(name: entry.path, isDirectory: entry.isDirectory),
  ];

  @override
  Future<Uint8List> readEntry(String name) async {
    final entry = _reader.entries.firstWhereOrNull(
      (entry) => entry.isFile && entry.path == name,
    );

    if (entry == null) {
      throw FileNotFound(path: name);
    }

    // copy bytes from the reader's internal buffer into something we own
    final builder = BytesBuilder();

    try {
      await for (final chunk in _reader.openRead(entry)) {
        builder.add(chunk);
      }
    } on ArchiveException catch (e) {
      throw InvalidArchive(path, reason: e.message, previous: e);
    }

    return builder.takeBytes();
  }
}
