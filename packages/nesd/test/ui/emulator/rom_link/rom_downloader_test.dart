import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/invalid_rom_link.dart';
import 'package:nesd/exception/rom_download_failed.dart';
import 'package:nesd/exception/rom_too_large.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/ui/emulator/rom_link/rom_downloader.dart';
import 'package:nesd/ui/emulator/rom_link/rom_fetcher.dart';

import 'fake_rom_fetcher.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  RomDownloader downloader(FakeRomFetcher fetcher) =>
      RomDownloader(fetcher: fetcher, maxBytes: 8);

  group('RomDownloader', () {
    test('returns the name and bytes of the ROM', () async {
      final fetcher = FakeRomFetcher.bytes(bytes);

      final rom = await downloader(
        fetcher,
      ).download(Uri.parse('https://example.com/roms/My%20Game.nes?v=2'));

      expect(rom.name, 'My Game.nes');
      expect(rom.bytes, bytes);
      expect(fetcher.requests, [
        Uri.parse('https://example.com/roms/My%20Game.nes?v=2'),
      ]);
    });

    test('accepts archives with upper-case extensions', () async {
      final fetcher = FakeRomFetcher.bytes(bytes);

      for (final name in ['game.zip', 'game.7z', 'GAME.NES']) {
        final rom = await downloader(
          fetcher,
        ).download(Uri.parse('https://example.com/$name'));

        expect(rom.name, name);
      }
    });

    test('refuses an unsupported extension without fetching', () async {
      final fetcher = FakeRomFetcher.bytes(bytes);

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/a.txt')),
        throwsA(isA<UnsupportedFileType>()),
      );

      expect(fetcher.requests, isEmpty);
    });

    test('refuses a URL that does not name a file', () async {
      final fetcher = FakeRomFetcher.bytes(bytes);

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/')),
        throwsA(isA<InvalidRomLink>()),
      );

      expect(fetcher.requests, isEmpty);
    });

    test('reports an HTTP error status', () async {
      final fetcher = FakeRomFetcher(
        (_) async => RomResponse(status: 404, bytes: () async => bytes),
      );

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/a.nes')),
        throwsA(
          isA<RomDownloadFailed>().having(
            (e) => e.message,
            'message',
            contains('404'),
          ),
        ),
      );
    });

    test('refuses an announced size over the limit before reading', () async {
      var read = false;

      final fetcher = FakeRomFetcher(
        (_) async => RomResponse(
          status: 200,
          contentLength: 9,
          bytes: () async {
            read = true;

            return bytes;
          },
        ),
      );

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/a.nes')),
        throwsA(isA<RomTooLarge>()),
      );

      expect(read, isFalse);
    });

    test('refuses a body over the limit without a length header', () async {
      final fetcher = FakeRomFetcher.bytes(Uint8List(9));

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/a.nes')),
        throwsA(isA<RomTooLarge>()),
      );
    });

    test('passes fetcher failures through', () async {
      final fetcher = FakeRomFetcher(
        (_) async => throw RomDownloadFailed('unreachable'),
      );

      await expectLater(
        downloader(fetcher).download(Uri.parse('https://example.com/a.nes')),
        throwsA(isA<RomDownloadFailed>()),
      );
    });
  });
}
