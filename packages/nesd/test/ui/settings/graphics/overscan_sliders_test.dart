import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/settings/graphics/overscan_sliders.dart';
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

  Overscan readOverscan(WidgetTester tester, Type widget) {
    final element = tester.element(find.byType(widget));

    return ProviderScope.containerOf(
      element,
    ).read(settingsControllerProvider).overscan;
  }

  testWidgets('shows one slider per side', (tester) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const OverscanSliders()));

    expect(find.text('Overscan Top'), findsOneWidget);
    expect(find.text('Overscan Bottom'), findsOneWidget);
    expect(find.text('Overscan Left'), findsOneWidget);
    expect(find.text('Overscan Right'), findsOneWidget);
  });

  testWidgets('dragging the top slider changes only the top crop', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const OverscanTopSlider()));

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pumpAndSettle();

    final overscan = readOverscan(tester, OverscanTopSlider);

    expect(overscan.top, lessThan(8));
    expect(overscan.bottom, 8);
  });

  testWidgets('tapping the top slider label resets it to 8', (tester) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const OverscanTopSlider()));

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(readOverscan(tester, OverscanTopSlider).top, isNot(8));

    await tester.tap(find.text('Overscan Top'));
    await tester.pumpAndSettle();

    expect(readOverscan(tester, OverscanTopSlider).top, 8);
  });

  testWidgets('tapping the left slider label resets it to 0', (tester) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const OverscanLeftSlider()));

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(readOverscan(tester, OverscanLeftSlider).left, isNot(0));

    await tester.tap(find.text('Overscan Left'));
    await tester.pumpAndSettle();

    expect(readOverscan(tester, OverscanLeftSlider).left, 0);
  });

  testWidgets('dragging past the end clamps to the maximum crop', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const OverscanRightSlider()));

    await tester.drag(find.byType(Slider), const Offset(5000, 0));
    await tester.pumpAndSettle();

    expect(readOverscan(tester, OverscanRightSlider).right, maxOverscan);
  });
}
