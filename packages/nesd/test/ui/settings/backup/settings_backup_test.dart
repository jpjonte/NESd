import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/backup/settings_backup.dart';
import 'package:nesd/ui/settings/settings.dart';

const _rom = RomInfo(
  file: FilesystemFile(
    path: '/roms/game.nes',
    name: 'game.nes',
    type: FilesystemFileType.file,
  ),
  hash: 'abc',
);

void main() {
  final now = DateTime.utc(2026, 10, 10, 12, 30, 5);

  group('encodeSettingsBackup', () {
    test('wraps the settings behind a version key', () {
      final json =
          jsonDecode(encodeSettingsBackup(Settings(volume: 0.5), now: now))
              as Map<String, dynamic>;

      expect(json['version'], settingsBackupVersion);
      expect(json['exportedAt'], '2026-10-10T12:30:05.000Z');
      expect((json['settings'] as Map)['volume'], 0.5);
    });

    test('leaves out the device-specific fields', () {
      final settings = Settings(
        recentRoms: [_rom],
        recentRomPaths: ['/roms/game.nes'],
        favoriteRoms: [_rom],
        lastRomPath: const FilesystemFile(
          path: '/roms',
          name: 'roms',
          type: FilesystemFileType.directory,
        ),
      );

      final json =
          jsonDecode(encodeSettingsBackup(settings, now: now))
              as Map<String, dynamic>;
      final exported = json['settings'] as Map<String, dynamic>;

      expect(
        Settings().toJson().keys.toSet().difference(exported.keys.toSet()),
        deviceSpecificSettingsKeys,
      );
    });

    test('keeps cheats', () {
      final settings = Settings(
        cheats: {
          'abc': [
            Cheat(
              id: '1',
              name: 'Lives',
              type: CheatType.gameGenie,
              address: 0x1234,
              value: 9,
              code: 'SXIOPO',
            ),
          ],
        },
      );

      final json =
          jsonDecode(encodeSettingsBackup(settings, now: now))
              as Map<String, dynamic>;

      expect((json['settings'] as Map)['cheats'], isNotEmpty);
    });
  });

  group('decodeSettingsBackup', () {
    test('returns the settings of an exported file', () {
      final decoded = decodeSettingsBackup(
        encodeSettingsBackup(Settings(volume: 0.25), now: now),
      );

      expect(decoded['volume'], 0.25);
    });

    test('strips device-specific fields a hand-edited file carries', () {
      final decoded = decodeSettingsBackup(
        jsonEncode({
          'version': 1,
          'settings': {
            'volume': 0.25,
            'recentRomPaths': ['/roms/game.nes'],
          },
        }),
      );

      expect(decoded, {'volume': 0.25});
    });

    test('rejects a file that is not JSON', () {
      expect(
        () => decodeSettingsBackup('not json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'not a NESd settings file',
          ),
        ),
      );
    });

    test('rejects JSON without a settings object', () {
      for (final source in [
        '[]',
        '{"version": 1}',
        '{"version": 1, "settings": []}',
      ]) {
        expect(
          () => decodeSettingsBackup(source),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'not a NESd settings file',
            ),
          ),
          reason: source,
        );
      }
    });

    test('rejects a file without a version', () {
      expect(
        () => decodeSettingsBackup('{"settings": {}}'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'not a NESd settings file',
          ),
        ),
      );
    });

    test('rejects a file from a newer version', () {
      expect(
        () => decodeSettingsBackup(
          jsonEncode({'version': settingsBackupVersion + 1, 'settings': {}}),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'made by a newer version of NESd',
          ),
        ),
      );
    });
  });

  test('the file name carries a timestamp', () {
    expect(
      settingsBackupFileName(DateTime(2026, 10, 10, 9, 5, 3)),
      'nesd-settings-20261010-090503.json',
    );
  });
}
