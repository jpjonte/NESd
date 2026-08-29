import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/settings/controls/turbo_speed_selector.dart';
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

  testWidgets('the speed segments fit a phone-width settings tile', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(360, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: nesdThemeLight,
          home: const Scaffold(body: TurboSpeedSelector()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('30 Hz'), findsOneWidget);
    expect(find.text('7.5 Hz'), findsOneWidget);
  });
}
