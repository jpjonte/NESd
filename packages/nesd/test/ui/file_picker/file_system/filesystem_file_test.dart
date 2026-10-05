import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main() {
  const file = FilesystemFile(
    path: '/roms/game.nes',
    name: 'game.nes',
    type: FilesystemFileType.file,
  );

  test('two files describing the same entry are equal', () {
    const other = FilesystemFile(
      path: '/roms/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.file,
    );

    expect(file, other);
    expect(file.hashCode, other.hashCode);
  });

  test('a different path makes two files unequal', () {
    const other = FilesystemFile(
      path: '/roms/jp/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.file,
    );

    expect(file, isNot(other));
  });

  test('a different name makes two files unequal', () {
    const other = FilesystemFile(
      path: '/roms/game.nes',
      name: 'other.nes',
      type: FilesystemFileType.file,
    );

    expect(file, isNot(other));
  });

  test('a different type makes two files unequal', () {
    const other = FilesystemFile(
      path: '/roms/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.directory,
    );

    expect(file, isNot(other));
  });

  test('a round trip through JSON preserves equality', () {
    expect(FilesystemFile.fromJson(file.toJson()), file);
  });

  test('modified is read from epoch milliseconds', () {
    final listed = FilesystemFile.fromJson(const {
      'path': '/roms/game.nes',
      'name': 'game.nes',
      'type': 'file',
      'modified': 1700000000000,
    });

    expect(listed.modified, DateTime.fromMillisecondsSinceEpoch(1700000000000));
  });

  test('a missing modified reads as null', () {
    expect(FilesystemFile.fromJson(file.toJson()).modified, isNull);
  });

  test('modified is never persisted', () {
    final listed = FilesystemFile(
      path: '/roms/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.file,
      modified: DateTime(2026),
    );

    expect(listed.toJson().containsKey('modified'), isFalse);
  });

  test('modified does not take part in equality', () {
    final listed = FilesystemFile(
      path: '/roms/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.file,
      modified: DateTime(2026),
    );

    expect(listed, file);
    expect(listed.hashCode, file.hashCode);
  });
}
