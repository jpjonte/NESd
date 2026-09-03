import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_system/archive_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

const _sevenZip = 'test/fixtures/archive/dirs.7z';
const _zip = '/roms/implicit.zip';

void main() {
  group('splitArchivePath', () {
    test('splits an entry path from the archive that holds it', () {
      expect(splitArchivePath('/roms/collection.7z:A/Astyanax.nes'), (
        archivePath: '/roms/collection.7z',
        entryPath: 'A/Astyanax.nes',
      ));
    });

    test('splits a Windows archive path from the right', () {
      expect(splitArchivePath(r'C:\roms\collection.zip:game.nes'), (
        archivePath: r'C:\roms\collection.zip',
        entryPath: 'game.nes',
      ));
    });

    test('returns null for a path that holds no archive', () {
      expect(splitArchivePath('/roms/nestest.nes'), isNull);
      expect(splitArchivePath(r'C:\roms\nestest.nes'), isNull);
      expect(splitArchivePath('/roms/collection.7z'), isNull);
    });
  });

  group('isWithinDirectory', () {
    test('counts an archive as containing its entries', () {
      expect(
        isWithinDirectory('/roms/c.7z', '/roms/c.7z:A'),
        isTrue,
        reason: 'plain isWithin reads c.7z:A as a sibling of c.7z',
      );
      expect(isWithinDirectory('/roms/c.7z', '/roms/c.7z:A/game.nes'), isTrue);
    });

    test('counts a folder as containing what is below it', () {
      expect(isWithinDirectory('/roms/c.7z:A', '/roms/c.7z:A/B'), isTrue);
      expect(isWithinDirectory('/roms/c.7z:A', '/roms/c.7z:B/x.nes'), isFalse);
    });

    test('counts a directory as containing the archives in it', () {
      expect(isWithinDirectory('/roms', '/roms/c.7z:A'), isTrue);
      expect(isWithinDirectory('/other', '/roms/c.7z:A'), isFalse);
    });

    test('separates entries of different archives', () {
      expect(isWithinDirectory('/roms/a.7z', '/roms/b.7z:A'), isFalse);
    });

    test('falls back to plain containment outside archives', () {
      expect(isWithinDirectory('/roms', '/roms/sub/game.nes'), isTrue);
      expect(isWithinDirectory('/roms', '/other/game.nes'), isFalse);
      expect(isWithinDirectory('/roms', '/roms'), isFalse);
    });
  });

  group('ArchiveFilesystem.list', () {
    test('lists only the immediate children of the archive root', () async {
      final filesystem = await _openSevenZip();

      expect(await _childrenOf(filesystem, _sevenZip), {
        'nested': FilesystemFileType.directory,
      });
    });

    test('lists the children of a directory inside the archive', () async {
      final filesystem = await _openSevenZip();

      expect(await _childrenOf(filesystem, '$_sevenZip:nested'), {
        'sub': FilesystemFileType.directory,
        'scanline.nes': FilesystemFileType.file,
      });
    });

    test('qualifies child paths with the archive that holds them', () async {
      final filesystem = await _openSevenZip();

      final children = await filesystem.list('$_sevenZip:nested');

      expect(
        children.map((child) => child.path),
        containsAll(<String>[
          '$_sevenZip:nested/sub',
          '$_sevenZip:nested/scanline.nes',
        ]),
      );
    });

    test('synthesizes directories the archive stores no entry for', () async {
      final filesystem = await _openImplicitZip();

      expect(await _childrenOf(filesystem, _zip), {
        'A': FilesystemFileType.directory,
        'root.nes': FilesystemFileType.file,
      });
      expect(await _childrenOf(filesystem, '$_zip:A'), {
        'B': FilesystemFileType.directory,
        'game1.nes': FilesystemFileType.file,
      });
    });

    test('keeps entries flat so the loader still finds nested ROMs', () async {
      final filesystem = await _openImplicitZip();

      expect(filesystem.entries.map((entry) => entry.name), [
        'root.nes',
        'A/game1.nes',
        'A/B/game2.nes',
      ]);
    });
  });
}

Future<Map<String, FilesystemFileType>> _childrenOf(
  ArchiveFilesystem filesystem,
  String path,
) async {
  final children = await filesystem.list(path);

  return {for (final child in children) child.name: child.type};
}

Future<ArchiveFilesystem> _openSevenZip() => ArchiveFilesystem.open(
  path: _sevenZip,
  data: File(_sevenZip).readAsBytesSync(),
);

Future<ArchiveFilesystem> _openImplicitZip() {
  final archive = Archive();

  for (final name in ['root.nes', 'A/game1.nes', 'A/B/game2.nes']) {
    final bytes = Uint8List.fromList([name.length]);

    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  return ArchiveFilesystem.open(
    path: _zip,
    data: Uint8List.fromList(ZipEncoder().encode(archive)),
  );
}
