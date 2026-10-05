import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_sort_order.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

FilesystemFile _file(String name, {DateTime? modified}) => FilesystemFile(
  path: '/roms/$name',
  name: name,
  type: FilesystemFileType.file,
  modified: modified,
);

FilesystemFile _directory(String name) => FilesystemFile(
  path: '/roms/$name',
  name: name,
  type: FilesystemFileType.directory,
);

RomInfo _recent(String path) => RomInfo(
  file: FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
);

void main() {
  final a = _file('a.nes', modified: DateTime(2020));
  final b = _file('B.nes', modified: DateTime(2022));
  final c = _file('c.nes');
  final directory = _directory('zz');

  List<String> sorted(
    FileSortOrder order, {
    List<RomInfo> recentRoms = const [],
  }) => [
    for (final file in sortFiles(
      [c, b, directory, a],
      order: order,
      recentRoms: recentRoms,
    ))
      file.name,
  ];

  test('name orders compare case-insensitively, directories first', () {
    expect(sorted(FileSortOrder.nameAscending), [
      'zz',
      'a.nes',
      'B.nes',
      'c.nes',
    ]);
    expect(sorted(FileSortOrder.nameDescending), [
      'zz',
      'c.nes',
      'B.nes',
      'a.nes',
    ]);
  });

  test('modified orders put unknown times last, by name', () {
    expect(sorted(FileSortOrder.modifiedNewest), [
      'zz',
      'B.nes',
      'a.nes',
      'c.nes',
    ]);
    expect(sorted(FileSortOrder.modifiedOldest), [
      'zz',
      'a.nes',
      'B.nes',
      'c.nes',
    ]);
  });

  test('played orders follow the recent list, unplayed files last', () {
    final recentRoms = [_recent('/roms/c.nes'), _recent('/roms/a.nes')];

    expect(sorted(FileSortOrder.lastPlayedNewest, recentRoms: recentRoms), [
      'zz',
      'c.nes',
      'a.nes',
      'B.nes',
    ]);
    expect(sorted(FileSortOrder.lastPlayedOldest, recentRoms: recentRoms), [
      'zz',
      'a.nes',
      'c.nes',
      'B.nes',
    ]);
  });

  test('an archive row ranks by its most recently played entry', () {
    final archive = _file('pack.zip');
    final recentRoms = [
      _recent('/roms/a.nes'),
      _recent('/roms/pack.zip:inner/game.nes'),
      _recent('/roms/pack.zip:other.nes'),
    ];

    final ranks = playedRanks([archive, a], recentRoms);

    expect(ranks, {'/roms/a.nes': 0, '/roms/pack.zip': 1});
  });

  test('next cycles through every order and wraps', () {
    var order = FileSortOrder.nameAscending;
    final seen = <FileSortOrder>[];

    for (var i = 0; i < FileSortOrder.values.length; i++) {
      seen.add(order);
      order = order.next;
    }

    expect(seen, FileSortOrder.values);
    expect(order, FileSortOrder.nameAscending);
  });

  test('only the name orders are by name', () {
    expect(
      [
        for (final order in FileSortOrder.values)
          if (order.byName) order,
      ],
      [FileSortOrder.nameAscending, FileSortOrder.nameDescending],
    );
  });
}
