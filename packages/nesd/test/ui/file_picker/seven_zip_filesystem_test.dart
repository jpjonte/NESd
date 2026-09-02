import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/exception/invalid_archive.dart';
import 'package:nesd/ui/file_picker/file_system/archive_filesystem.dart';

void main() {
  final nestest = _rom('nestest/nestest.nes');
  final scanline = _rom('scanline/scanline.nes');

  group('SevenZipFilesystem', () {
    test('lists the entries of an LZMA2 archive', () async {
      final filesystem = await _open('single_rom.7z');

      final files = await filesystem.list('single_rom.7z');

      expect(files.map((file) => file.name), ['nestest.nes']);
    });

    test('reads an entry back byte-for-byte', () async {
      final filesystem = await _open('single_rom.7z');

      expect(await filesystem.read('nestest.nes'), nestest);
    });

    test('reads each entry of a solid archive', () async {
      final filesystem = await _open('solid_roms.7z');

      expect(await filesystem.read('nestest.nes'), nestest);
      expect(await filesystem.read('scanline.nes'), scanline);
    });

    for (final (name, description) in const [
      ('lzma1.7z', 'LZMA1'),
      ('copy.7z', 'stored entries'),
      ('bcj.7z', 'a BCJ filter chain'),
      ('hdr.7z', 'a compressed header'),
    ]) {
      test('reads an archive using $description', () async {
        final filesystem = await _open(name);

        expect(await filesystem.read('nestest.nes'), nestest);
      });
    }

    test('keeps the directory structure of a nested archive', () async {
      final filesystem = await _open('dirs.7z');

      expect(
        {for (final entry in filesystem.entries) entry.name: entry.isDirectory},
        {
          'nested': true,
          'nested/sub': true,
          'nested/scanline.nes': false,
          'nested/sub/nestest.nes': false,
        },
      );
      expect(await filesystem.read('nested/sub/nestest.nes'), nestest);
    });

    test('reports a codec it cannot decode as a NesdException', () async {
      final filesystem = await _open('ppmd.7z');

      await expectLater(
        filesystem.read('nestest.nes'),
        throwsA(isA<InvalidArchive>()),
      );
    });

    test('rejects an entry the archive does not hold', () async {
      final filesystem = await _open('single_rom.7z');

      await expectLater(
        filesystem.read('missing.nes'),
        throwsA(isA<FileNotFound>()),
      );
    });
  });
}

Future<ArchiveFilesystem> _open(String name) {
  final path = 'test/fixtures/archive/$name';

  return ArchiveFilesystem.open(path: path, data: File(path).readAsBytesSync());
}

Uint8List _rom(String path) => File('../../roms/test/$path').readAsBytesSync();
