import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/video_filter_switches.dart';
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

  testWidgets('toggling both switches enables the canonical chain', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Column(children: [SmoothingFilterSwitch(), CrtFilterSwitch()]),
      ),
    );

    await tester.tap(find.text('CRT effect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smoothing'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(CrtFilterSwitch));
    final container = ProviderScope.containerOf(element);

    expect(container.read(settingsControllerProvider).videoFilters, [
      VideoFilter.smooth,
      VideoFilter.crt,
    ]);
  });

  testWidgets('toggling CRT off removes only crt', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(children: [SmoothingFilterSwitch(), CrtFilterSwitch()]),
      ),
    );

    await tester.tap(find.text('Smoothing'));
    await tester.tap(find.text('CRT effect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CRT effect'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(CrtFilterSwitch));
    final container = ProviderScope.containerOf(element);

    expect(container.read(settingsControllerProvider).videoFilters, [
      VideoFilter.smooth,
    ]);
  });

  testWidgets('dragging the scanline slider changes the CRT settings', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const ScanlineIntensitySlider()));

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ScanlineIntensitySlider));
    final container = ProviderScope.containerOf(element);

    expect(
      container.read(settingsControllerProvider).crtFilter.scanlineIntensity,
      isNot(0.35),
    );
  });
}
