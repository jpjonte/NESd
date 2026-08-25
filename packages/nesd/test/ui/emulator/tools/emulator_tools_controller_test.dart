import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
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
          ..listen(emulatorToolsControllerProvider, (_, _) {});

    addTearDown(container.dispose);
  });

  test('toggle opens a closed tool and writes through to the settings', () {
    container
        .read(emulatorToolsControllerProvider.notifier)
        .toggle(EmulatorTool.debugger);

    expect(container.read(emulatorToolsControllerProvider), {
      EmulatorTool.debugger,
    });
    expect(container.read(settingsControllerProvider).openTools, {
      EmulatorTool.debugger,
    });
  });

  test('toggle closes an open tool', () {
    container.read(emulatorToolsControllerProvider.notifier)
      ..toggle(EmulatorTool.debugger)
      ..toggle(EmulatorTool.debugger);

    expect(container.read(emulatorToolsControllerProvider), isEmpty);
  });

  test('open and close are idempotent and independent per tool', () {
    final tools = container.read(emulatorToolsControllerProvider.notifier)
      ..open(EmulatorTool.debugger)
      ..open(EmulatorTool.debugger)
      ..open(EmulatorTool.apuDebug);

    expect(container.read(emulatorToolsControllerProvider), {
      EmulatorTool.debugger,
      EmulatorTool.apuDebug,
    });

    tools
      ..close(EmulatorTool.debugger)
      ..close(EmulatorTool.debugger);

    expect(container.read(emulatorToolsControllerProvider), {
      EmulatorTool.apuDebug,
    });
    expect(tools.isOpen(EmulatorTool.apuDebug), isTrue);
    expect(tools.isOpen(EmulatorTool.debugger), isFalse);
  });

  test('the state seeds from the persisted settings', () {
    container.read(settingsControllerProvider.notifier).openTools = {
      EmulatorTool.tileViewer,
    };

    expect(container.read(emulatorToolsControllerProvider), {
      EmulatorTool.tileViewer,
    });
  });

  group('the debugger gate (isToolAvailable / availableTools)', () {
    test('refuses debugger-toolset tools when the gate is off', () {
      for (final tool in [
        EmulatorTool.debugger,
        EmulatorTool.apuDebug,
        EmulatorTool.executionLog,
      ]) {
        expect(
          isToolAvailable(tool, debuggerEnabled: false),
          isFalse,
          reason: '$tool',
        );
      }
    });

    test('allows non-debugger tools regardless of the gate', () {
      for (final tool in [
        EmulatorTool.display,
        EmulatorTool.tileViewer,
        EmulatorTool.cartridgeInfo,
      ]) {
        expect(isToolAvailable(tool, debuggerEnabled: false), isTrue);
        expect(isToolAvailable(tool, debuggerEnabled: true), isTrue);
      }
    });

    test('allows every tool when the gate is on', () {
      for (final tool in EmulatorTool.values) {
        expect(isToolAvailable(tool, debuggerEnabled: true), isTrue);
      }
    });

    test('availableTools strips only the debugger toolset when off', () {
      final filtered = availableTools(
        EmulatorTool.values.toSet(),
        debuggerEnabled: false,
      );

      expect(filtered, {
        EmulatorTool.display,
        EmulatorTool.tileViewer,
        EmulatorTool.cartridgeInfo,
      });
    });
  });
}
