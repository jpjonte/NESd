import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/tools/audio_tool.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late _MockSharedPreferences prefs;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    String settingsJson,
  ) async {
    when(() => prefs.getString(any())).thenReturn(settingsJson);

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: const Scaffold(body: AudioToolWidget()),
        ),
      ),
    );

    return ProviderScope.containerOf(
      tester.element(find.byType(AudioToolWidget)),
    );
  }

  testWidgets('shows the same controls as the Audio settings tab', (
    tester,
  ) async {
    await pump(tester, '{}');

    expect(find.byType(VolumeSlider), findsOneWidget);
    expect(find.byType(LowPassFilterSwitch), findsOneWidget);
    expect(find.byType(SwapDutyCyclesSwitch), findsOneWidget);
  });

  testWidgets('a switch in the tool writes through to the setting', (
    tester,
  ) async {
    final container = await pump(tester, '{}');

    expect(container.read(settingsControllerProvider).swapDutyCycles, isFalse);

    await tester.tap(
      find.descendant(
        of: find.byType(SwapDutyCyclesSwitch),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump();

    expect(container.read(settingsControllerProvider).swapDutyCycles, isTrue);
  });

  testWidgets('the tool reflects a setting stored elsewhere', (tester) async {
    await pump(tester, '{"lowPassFilter":true}');

    final toggle = tester.widget<Switch>(
      find.descendant(
        of: find.byType(LowPassFilterSwitch),
        matching: find.byType(Switch),
      ),
    );

    expect(toggle.value, isTrue);
  });
}
