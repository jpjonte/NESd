import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/emulator/tools/display_tool.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_slider.dart';
import 'package:nesd/ui/settings/graphics/renderer_selector.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
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
          home: const Scaffold(body: DisplayToolWidget()),
        ),
      ),
    );

    return ProviderScope.containerOf(
      tester.element(find.byType(DisplayToolWidget)),
    );
  }

  testWidgets('shows no CRT sliders while the filter is off', (tester) async {
    await pump(tester, '{}');

    expect(find.text('Smoothing'), findsOneWidget);
    expect(find.text('CRT effect'), findsOneWidget);
    expect(find.byType(ScanlineIntensitySlider), findsNothing);
    expect(find.byType(MaskStrengthSlider), findsNothing);
    expect(find.byType(CurvatureSlider), findsNothing);
    expect(find.byType(RendererSelector), findsNothing);
  });

  testWidgets('shows the CRT sliders when the CRT filter is active', (
    tester,
  ) async {
    final container = await pump(tester, '{"videoFilters":["crt"]}');

    expect(container.read(settingsControllerProvider).videoFilters, [
      VideoFilter.crt,
    ]);
    expect(find.byType(ScanlineIntensitySlider), findsOneWidget);
    expect(find.byType(MaskStrengthSlider), findsOneWidget);
    expect(find.byType(CurvatureSlider), findsOneWidget);
  });

  testWidgets('enables the custom PAR slider only for custom PAR', (
    tester,
  ) async {
    await pump(tester, '{"pixelAspectRatio":"custom"}');

    final slider = tester.widget<PixelAspectRatioSlider>(
      find.byType(PixelAspectRatioSlider),
    );

    expect(slider.enabled, isTrue);
  });

  testWidgets('dropdowns fill the tool column width', (tester) async {
    when(() => prefs.getString(any())).thenReturn('{}');

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fontLoader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));

    await fontLoader.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: SizedBox(width: 512, child: DisplayToolWidget()),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(Dropdown<Scaling>)).width,
      greaterThan(400),
    );
    expect(
      tester.getSize(find.byType(Dropdown<PixelAspectRatio>)).width,
      greaterThan(400),
    );
  });
}
