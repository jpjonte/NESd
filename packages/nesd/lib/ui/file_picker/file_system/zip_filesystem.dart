import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/ui/file_picker/file_system/archive_filesystem.dart';

class ZipFilesystem extends ArchiveFilesystem {
  ZipFilesystem({required super.path, required Uint8List zipData})
    : archive = ZipDecoder().decodeBytes(zipData);

  final Archive archive;

  @override
  late final List<ArchiveEntryInfo> entries = [
    for (final file in archive.files)
      ArchiveEntryInfo(name: file.name, isDirectory: !file.isFile),
  ];

  @override
  Future<Uint8List> readEntry(String name) async {
    final file = archive.files.firstWhereOrNull((file) => file.name == name);

    if (file == null) {
      throw FileNotFound(path: name);
    }

    return Uint8List.fromList(file.content as List<int>);
  }
}
