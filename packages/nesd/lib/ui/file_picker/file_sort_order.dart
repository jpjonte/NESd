import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

enum FileSortOrder {
  nameAscending('Name ↑'),
  nameDescending('Name ↓'),
  lastPlayedNewest('Played ↓'),
  lastPlayedOldest('Played ↑'),
  modifiedNewest('Modified ↓'),
  modifiedOldest('Modified ↑');

  const FileSortOrder(this.label);

  final String label;

  bool get byName => this == nameAscending || this == nameDescending;

  FileSortOrder get next => values[(index + 1) % values.length];
}

Map<String, int> playedRanks(
  List<FilesystemFile> files,
  List<RomInfo> recentRoms,
) {
  final paths = {for (final file in files) file.path};
  final ranks = <String, int>{};

  for (final (index, rom) in recentRoms.indexed) {
    final path = rom.file.path;
    final row = paths.contains(path)
        ? path
        : splitArchivePath(path)?.archivePath;

    if (row != null && paths.contains(row)) {
      ranks.putIfAbsent(row, () => index);
    }
  }

  return ranks;
}

int compareFiles(
  FilesystemFile a,
  FilesystemFile b, {
  required FileSortOrder order,
  required Map<String, int> playedRank,
}) {
  final aDirectory = a.type == FilesystemFileType.directory;
  final bDirectory = b.type == FilesystemFileType.directory;

  if (aDirectory != bDirectory) {
    return aDirectory ? -1 : 1;
  }

  final byName = _compareNames(a, b);

  if (aDirectory) {
    return byName;
  }

  final byKey = switch (order) {
    FileSortOrder.nameAscending => byName,
    FileSortOrder.nameDescending => -byName,
    FileSortOrder.lastPlayedNewest => _compareKnownFirst(
      playedRank[a.path],
      playedRank[b.path],
      (x, y) => x.compareTo(y),
    ),
    FileSortOrder.lastPlayedOldest => _compareKnownFirst(
      playedRank[a.path],
      playedRank[b.path],
      (x, y) => y.compareTo(x),
    ),
    FileSortOrder.modifiedNewest => _compareKnownFirst(
      a.modified,
      b.modified,
      (x, y) => y.compareTo(x),
    ),
    FileSortOrder.modifiedOldest => _compareKnownFirst(
      a.modified,
      b.modified,
      (x, y) => x.compareTo(y),
    ),
  };

  return byKey != 0 ? byKey : byName;
}

List<FilesystemFile> sortFiles(
  List<FilesystemFile> files, {
  required FileSortOrder order,
  required List<RomInfo> recentRoms,
}) {
  final ranks = playedRanks(files, recentRoms);

  return files.toList()
    ..sort((a, b) => compareFiles(a, b, order: order, playedRank: ranks));
}

int _compareNames(FilesystemFile a, FilesystemFile b) =>
    a.path.toLowerCase().compareTo(b.path.toLowerCase());

int _compareKnownFirst<T>(T? a, T? b, int Function(T, T) compare) =>
    switch ((a, b)) {
      (final a?, final b?) => compare(a, b),
      (_?, null) => -1,
      (null, _?) => 1,
      _ => 0,
    };
