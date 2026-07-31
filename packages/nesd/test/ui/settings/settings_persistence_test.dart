import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;
  late ProviderContainer container;
  late SettingsController controller;
  late List<String> printed;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');

    container =
        ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          )
          ..listen(settingsControllerProvider, (_, _) {})
          ..listen(toastStateProvider, (_, _) {});

    controller = container.read(settingsControllerProvider.notifier);

    printed = [];

    final originalDebugPrint = debugPrint;

    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');

    addTearDown(() => debugPrint = originalDebugPrint);
  });

  tearDown(() => container.dispose());

  test('a rejected settings write shows a warning toast', () async {
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);

    controller.showTiles = true;

    await pumpEventQueue();

    expect(controller.showTiles, isTrue);

    final toasts = container.read(toastStateProvider);

    expect(toasts, hasLength(1));
    expect(toasts.single.type, ToastType.warning);
    expect(toasts.single.message, contains('Failed to save settings'));
  });

  test('a throwing settings write shows a warning toast and logs the '
      'error', () async {
    when(
      () => prefs.setString(any(), any()),
    ).thenAnswer((_) async => throw Exception('disk full'));

    controller.showTiles = true;

    await pumpEventQueue();

    expect(controller.showTiles, isTrue);

    final toasts = container.read(toastStateProvider);

    expect(toasts, hasLength(1));
    expect(toasts.single.type, ToastType.warning);
    expect(toasts.single.message, contains('Failed to save settings'));

    expect(printed.join('\n'), contains('disk full'));
  });
}
