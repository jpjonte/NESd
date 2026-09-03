import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;
  late ProviderContainer container;
  late List<LogRecord> logged;
  late Map<String, String> writes;

  setUp(() {
    prefs = _MockSharedPreferences();
    logged = [];
    writes = {};

    when(() => prefs.setString(any(), any())).thenAnswer((invocation) async {
      final [String key, String value] = invocation.positionalArguments;

      writes[key] = value;

      return true;
    });

    NesdLog.install(
      NesdLog(sinks: [_RecordingSink(logged)], minimumLevel: LogLevel.debug),
    );

    addTearDown(() async {
      await NesdLog.instance.close();

      NesdLog.install(NesdLog());
    });
  });

  SettingsController load(Object raw, {String? backup}) {
    when(
      () => prefs.getString(SettingsController.settingsKey),
    ).thenReturn(raw is String ? raw : jsonEncode(raw));

    when(
      () => prefs.getString(SettingsController.settingsBackupKey),
    ).thenReturn(backup);

    container =
        ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          )
          ..listen(settingsControllerProvider, (_, _) {})
          ..listen(toastStateProvider, (_, _) {});

    addTearDown(container.dispose);

    return container.read(settingsControllerProvider.notifier);
  }

  test('a binding whose input cannot be read is dropped, not the whole '
      'binding list', () {
    final controller = load({
      'bindingsVersion': 2,
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
        {
          'index': 0,
          'action': 'ui.cancel',
          'type': 'hold',
          // a newer NESd writes slot-scoped bindings with no gamepadId
          'input': {'type': 'gamepad', 'inputs': <dynamic>[]},
        },
      ],
    });

    expect(controller.bindings.map((b) => b.action.code), ['ui.openMenu']);
  });

  test('a legacy map binding that cannot be read is dropped, not the whole '
      'map', () {
    final controller = load({
      'bindingsVersion': 2,
      'bindings': {
        'ui.openMenu': {
          'type': 'keyboard',
          'keys': [32],
        },
        'ui.cancel': {'type': 'gamepad', 'inputs': <dynamic>[]},
      },
    });

    expect(controller.bindings.map((b) => b.action.code), ['ui.openMenu']);
  });

  test('a dropped binding is surfaced rather than silently lost', () async {
    load({
      'bindingsVersion': 2,
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
        {
          'index': 0,
          'action': 'ui.cancel',
          'type': 'hold',
          'input': {'type': 'gamepad', 'inputs': <dynamic>[]},
        },
      ],
    });

    await pumpEventQueue();

    final record = logged.lastWhere(
      (r) => r.level == LogLevel.warning && r.channel == LogChannel.settings,
    );

    expect(record.context, containsPair('droppedBindings', 1));
    expect(container.read(toastStateProvider), hasLength(1));
    expect(
      logged.where(
        (r) => r.channel == LogChannel.input && r.level == LogLevel.warning,
      ),
      isNotEmpty,
    );
  });

  test('a setting with an unknown enum value falls back to its default '
      'without disturbing the others', () {
    final controller = load({'volume': 0.5, 'paletteId': 'hologram'});

    expect(controller.paletteId, NesPaletteId.defaultPalette);
    expect(controller.volume, 0.5);
  });

  test('a setting whose shape changed falls back to its default without '
      'disturbing the others', () {
    final controller = load({'volume': 0.5, 'crtFilter': 5});

    expect(controller.crtFilter, const CrtFilterSettings());
    expect(controller.volume, 0.5);
  });

  test('settings that are not valid JSON reset to defaults', () {
    final controller = load('{"volume": 0.5');

    expect(controller.volume, 1.0);
    expect(controller.bindings, isNotEmpty);
  });

  test('settings that are not a JSON object reset to defaults', () {
    final controller = load('[{"volume": 0.5}]');

    expect(controller.volume, 1.0);
    expect(controller.bindings, isNotEmpty);
  });

  test('a reset keeps a backup of the settings it could not read', () async {
    load('{"volume": 0.5');

    await pumpEventQueue();

    final backup =
        jsonDecode(writes[SettingsController.settingsBackupKey]!)
            as Map<String, dynamic>;

    expect(backup['settings'], '{"volume": 0.5');
    expect(DateTime.tryParse(backup['savedAt'] as String), isNotNull);
  });

  test('a reset dumps the settings it could not read to the log', () {
    load('{"volume": 0.5');

    final record = logged.lastWhere((r) => r.level == LogLevel.error);

    expect(record.channel, LogChannel.settings);
    expect(record.context, containsPair('settings', '{"volume": 0.5'));
    expect(record.error, contains('FormatException'));
  });

  test('a salvaged load logs which settings were dropped and why', () {
    load({'volume': 0.5, 'paletteId': 'hologram', 'crtFilter': 5});

    final record = logged.lastWhere((r) => r.level == LogLevel.warning);

    expect(record.channel, LogChannel.settings);

    final dropped = record.context!['dropped']! as Map<String, dynamic>;

    expect(dropped.keys, containsAll(['paletteId', 'crtFilter']));
    expect(dropped['paletteId'], contains('hologram'));
    expect(
      record.context,
      containsPair(
        'settings',
        '{"volume":0.5,"paletteId":"hologram","crtFilter":5}',
      ),
    );
  });

  test('a salvaged load keeps a backup of the original settings', () async {
    load({'volume': 0.5, 'paletteId': 'hologram'});

    await pumpEventQueue();

    final backup =
        jsonDecode(writes[SettingsController.settingsBackupKey]!)
            as Map<String, dynamic>;

    expect(backup['settings'], '{"volume":0.5,"paletteId":"hologram"}');
  });

  test('an existing backup is never overwritten by a later, poorer '
      'document', () async {
    load({
      'volume': 0.5,
      'paletteId': 'hologram',
    }, backup: '{"savedAt":"2026-01-01T00:00:00.000","settings":"{}"}');

    await pumpEventQueue();

    expect(writes, isNot(contains(SettingsController.settingsBackupKey)));
  });

  test('the backup outlives the settings it was taken from', () async {
    final controller = load({'volume': 0.5, 'paletteId': 'hologram'});

    await pumpEventQueue();

    controller.showDebugOverlay = true;

    await pumpEventQueue();

    final all = writes;

    expect(
      all,
      contains(SettingsController.settingsKey),
      reason:
          'the salvaged settings replace the original once anything '
          'is changed, which is exactly when the backup has to survive',
    );

    final backup =
        jsonDecode(all[SettingsController.settingsBackupKey]!)
            as Map<String, dynamic>;

    expect(backup['settings'], '{"volume":0.5,"paletteId":"hologram"}');
  });

  test('a recovery warns the user that a backup was kept', () async {
    load('{"volume": 0.5');

    await pumpEventQueue();

    final toasts = container.read(toastStateProvider);

    expect(toasts, hasLength(1));
    expect(toasts.single.type, ToastType.warning);
    expect(toasts.single.message, contains('backup'));
  });

  test('a recovery leaves the original settings in place so a newer NESd '
      'still finds them', () async {
    load({'volume': 0.5, 'paletteId': 'hologram'});

    await pumpEventQueue();

    expect(writes, isNot(contains(SettingsController.settingsKey)));
  });

  test('a backup that cannot be written is reported, not thrown', () async {
    when(
      () => prefs.setString(any(), any()),
    ).thenAnswer((_) async => throw Exception('disk full'));

    final controller = load('{"volume": 0.5');

    await pumpEventQueue();

    expect(controller.volume, 1.0);
    expect(
      logged.where(
        (r) => r.level == LogLevel.error && (r.error ?? '').contains('disk'),
      ),
      isNotEmpty,
    );
  });

  test('settings that read cleanly are neither backed up nor warned '
      'about', () async {
    load({'volume': 0.5});

    await pumpEventQueue();

    expect(writes, isEmpty);
    expect(
      logged.where((r) => r.level.index >= LogLevel.warning.index),
      isEmpty,
    );
    expect(container.read(toastStateProvider), isEmpty);
  });
}
