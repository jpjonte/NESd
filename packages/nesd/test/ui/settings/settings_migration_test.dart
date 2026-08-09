import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  SettingsController load(String raw) {
    when(() => prefs.getString(any())).thenReturn(raw);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    addTearDown(container.dispose);

    return container.read(settingsControllerProvider.notifier);
  }

  test('legacy show* booleans migrate to openTools', () {
    final controller = load(
      '{"showTiles": true, "showCartridgeInfo": false, '
      '"showDebugger": true, "showApuDebug": false}',
    );

    expect(controller.openTools, {
      EmulatorTool.tileViewer,
      EmulatorTool.debugger,
    });
  });

  test('an explicit empty openTools is not re-derived from the booleans', () {
    final controller = load('{"showTiles": true, "openTools": []}');

    expect(controller.openTools, isEmpty);
  });

  test('unknown tool names are dropped instead of throwing', () {
    final controller = load('{"openTools": ["debugger", "hologram"]}');

    expect(controller.openTools, {EmulatorTool.debugger});
  });

  test('settings with no tool keys start with nothing open', () {
    final controller = load('{}');

    expect(controller.openTools, isEmpty);
  });
}
