import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    container =
        ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          )
          ..listen(settingsControllerProvider, (_, _) {})
          ..listen(emulatorToolsControllerProvider, (_, _) {})
          ..listen(toolFocusControllerProvider, (_, _) {});

    addTearDown(container.dispose);
  });

  void openTools(Set<EmulatorTool> tools) =>
      container.read(settingsControllerProvider.notifier).openTools = tools;

  void enterEmulator() =>
      container.read(currentRouteProvider.notifier).update(EmulatorRoute.name);

  test('enter is a no-op with no navigable tool open', () {
    openTools({EmulatorTool.debugger});
    enterEmulator();

    container.read(toolFocusControllerProvider.notifier).enter();

    expect(container.read(toolFocusControllerProvider), isFalse);
  });

  test('enter focuses the panel when a navigable tool is open', () {
    openTools({EmulatorTool.audio});
    enterEmulator();

    container.read(toolFocusControllerProvider.notifier).enter();

    expect(container.read(toolFocusControllerProvider), isTrue);
  });

  test('toggle leaves the panel once focused', () {
    openTools({EmulatorTool.audio});
    enterEmulator();

    final controller = container.read(toolFocusControllerProvider.notifier)
      ..toggle();

    expect(container.read(toolFocusControllerProvider), isTrue);

    controller.toggle();

    expect(container.read(toolFocusControllerProvider), isFalse);
  });

  test('opening a second tool while focused keeps focus in the panel', () {
    openTools({EmulatorTool.audio});
    enterEmulator();

    container.read(toolFocusControllerProvider.notifier).enter();

    openTools({EmulatorTool.audio, EmulatorTool.display});

    expect(container.read(toolFocusControllerProvider), isTrue);
  });

  test('closing the last navigable tool exits', () {
    openTools({EmulatorTool.audio});
    enterEmulator();

    container.read(toolFocusControllerProvider.notifier).enter();

    openTools({EmulatorTool.debugger});

    expect(container.read(toolFocusControllerProvider), isFalse);
  });

  test('leaving the emulator route exits', () {
    openTools({EmulatorTool.audio});
    enterEmulator();

    container.read(toolFocusControllerProvider.notifier).enter();

    container.read(currentRouteProvider.notifier).update(MenuRoute.name);

    expect(container.read(toolFocusControllerProvider), isFalse);
  });
}
