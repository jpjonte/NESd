import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/backup/settings_backup.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rom = RomInfo(
  file: FilesystemFile(
    path: '/roms/game.nes',
    name: 'game.nes',
    type: FilesystemFileType.file,
  ),
  hash: 'abc',
);

const _lastRomPath = FilesystemFile(
  path: '/roms',
  name: 'roms',
  type: FilesystemFileType.directory,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 10, 10);

  Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    )..listen(toastStateProvider, (_, _) {});

    addTearDown(container.dispose);

    return container;
  }

  SettingsController controllerOf(ProviderContainer container) {
    container.listen(settingsControllerProvider, (_, _) {});

    return container.read(settingsControllerProvider.notifier);
  }

  Map<String, dynamic> backupOf(Settings settings) =>
      decodeSettingsBackup(encodeSettingsBackup(settings, now: now));

  tearDown(() => NesdLog.instance.minimumLevel = LogLevel.info);

  test('an exported file imports to the same settings', () async {
    final source = controllerOf(await containerWith({}))
      ..volume = 0.3
      ..turboSpeed = TurboSpeed.x2
      ..clearBinding(controller1A, 0);

    final exported = source.state;

    final target = controllerOf(await containerWith({}));
    final skipped = target.importBackup(backupOf(exported));

    expect(skipped, 0);
    expect(target.state, exported);
  });

  test('importing keeps the device-specific fields', () async {
    final target = controllerOf(await containerWith({}))
      ..addRecentRom(_rom)
      ..addFavorite(_rom)
      ..lastRomPath = _lastRomPath
      ..importBackup({'volume': 0.4});

    expect(target.state.volume, 0.4);
    expect(target.state.recentRoms, [_rom]);
    expect(target.state.favoriteRoms, [_rom]);
    expect(target.state.lastRomPath, _lastRomPath);
  });

  test('fields the file does not carry keep their current values', () async {
    final target = controllerOf(await containerWith({}))
      ..volume = 0.2
      ..importBackup({'lowPassFilter': true});

    expect(target.state.volume, 0.2);
    expect(target.state.lowPassFilter, isTrue);
  });

  test('an unreadable field is skipped and keeps its current value', () async {
    final target = controllerOf(await containerWith({}))..volume = 0.2;

    final skipped = target.importBackup({
      'volume': 'loud',
      'lowPassFilter': true,
    });

    expect(skipped, 1);
    expect(target.state.volume, 0.2);
    expect(target.state.lowPassFilter, isTrue);
  });

  test('an import is persisted', () async {
    final container = await containerWith({});

    controllerOf(container).importBackup({'volume': 0.4});
    await pumpEventQueue();

    final stored =
        jsonDecode(
              container
                  .read(sharedPreferencesProvider)
                  .getString(SettingsController.settingsKey)!,
            )
            as Map<String, dynamic>;

    expect(stored['volume'], 0.4);
  });

  test('an import applies its log level', () async {
    controllerOf(await containerWith({})).importBackup({'logLevel': 'debug'});

    expect(NesdLog.instance.minimumLevel, LogLevel.debug);
  });

  test('bindings from an older version are migrated', () async {
    final target = controllerOf(await containerWith({}))
      ..importBackup({
        'bindingsVersion': 5,
        'bindings': [
          {
            'index': 0,
            'action': 'ui.openMenu',
            'type': 'hold',
            'input': {
              'type': 'keyboard',
              'keys': [32],
            },
          },
        ],
      });

    expect(target.state.bindingsVersion, 6);
    expect(target.state.bindings, containsAll(defaultSortBindings));
  });

  test('reset restores the defaults but keeps the device-specific '
      'fields', () async {
    final defaults = controllerOf(await containerWith({})).state;

    final target = controllerOf(await containerWith({}))
      ..volume = 0.2
      ..clearBinding(controller1A, 0)
      ..addRecentRom(_rom)
      ..addFavorite(_rom)
      ..lastRomPath = _lastRomPath
      ..logLevel = LogLevel.debug
      ..resetToDefaults();

    expect(
      target.state,
      defaults.copyWith(
        recentRoms: [_rom],
        favoriteRoms: [_rom],
        lastRomPath: _lastRomPath,
      ),
    );
    expect(NesdLog.instance.minimumLevel, LogLevel.info);
  });
}
