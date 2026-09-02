import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/audio/mixer_sliders.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/theme/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late _MockSharedPreferences prefs;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: nesdThemeLight,
        home: Scaffold(body: child),
      ),
    );
  }

  MixerSettings readMixer(WidgetTester tester, Type widget) {
    final element = tester.element(find.byType(widget));

    return ProviderScope.containerOf(
      element,
    ).read(settingsControllerProvider).mixer;
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(child));
  }

  testWidgets('shows one slider per mixable channel', (tester) async {
    await pump(tester, const MixerSliders());

    expect(find.text('Pulse 1'), findsOneWidget);
    expect(find.text('Pulse 2'), findsOneWidget);
    expect(find.text('Triangle'), findsOneWidget);
    expect(find.text('Noise'), findsOneWidget);
    expect(find.text('DMC'), findsOneWidget);
    expect(find.text('MMC5'), findsOneWidget);
    expect(find.text('Namco 163'), findsOneWidget);
  });

  testWidgets('starts every channel at 100%', (tester) async {
    await pump(tester, const MixerSliders());

    expect(find.text('100'), findsNWidgets(7));
  });

  testWidgets('dragging one slider changes only that channel', (tester) async {
    await pump(tester, const Pulse1GainSlider());

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pumpAndSettle();

    final mixer = readMixer(tester, Pulse1GainSlider);

    expect(mixer.pulse1, lessThan(1.0));
    expect(mixer.pulse2, 1.0);
    expect(mixer.triangle, 1.0);
  });

  testWidgets('dragging fully left mutes the channel', (tester) async {
    await pump(tester, const TriangleGainSlider());

    await tester.drag(find.byType(Slider), const Offset(-5000, 0));
    await tester.pumpAndSettle();

    expect(readMixer(tester, TriangleGainSlider).triangle, 0.0);
  });

  testWidgets('tapping the label resets the channel to 100%', (tester) async {
    await pump(tester, const NoiseGainSlider());

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(readMixer(tester, NoiseGainSlider).noise, isNot(1.0));

    await tester.tap(find.text('Noise'));
    await tester.pumpAndSettle();

    expect(readMixer(tester, NoiseGainSlider).noise, 1.0);
  });

  testWidgets('holding increase stops at 100%', (tester) async {
    await pump(tester, const DmcGainSlider());

    final context = tester.element(find.byType(SliderSettingsTile));

    for (var i = 0; i < 40; i++) {
      Actions.invoke(context, const IncreaseIntent());
      await tester.pump();
    }

    expect(readMixer(tester, DmcGainSlider).dmc, 1.0);
  });

  testWidgets('holding decrease stops at silence', (tester) async {
    await pump(tester, const DmcGainSlider());

    final context = tester.element(find.byType(SliderSettingsTile));

    for (var i = 0; i < 40; i++) {
      Actions.invoke(context, const DecreaseIntent());
      await tester.pump();
    }

    expect(readMixer(tester, DmcGainSlider).dmc, 0.0);
  });

  testWidgets('each expansion slider drives its own chip', (tester) async {
    await pump(tester, const Mmc5GainSlider());

    await tester.drag(find.byType(Slider), const Offset(-5000, 0));
    await tester.pumpAndSettle();

    final mixer = readMixer(tester, Mmc5GainSlider);

    expect(mixer.mmc5, 0.0);
    expect(mixer.namco163, 1.0);
  });
}
