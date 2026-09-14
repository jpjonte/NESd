import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/general/theme_mode_selector.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

void main() {
  Future<Robot> focusThemeMode(WidgetTester tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();

    focusInto(tester, find.byType(ThemeModeSelector));
    await tester.pumpAndSettle();

    return r;
  }

  testWidgets('right and left step through the segments', (tester) async {
    final r = await focusThemeMode(tester);

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();
    expect(r.settings.themeMode, ThemeMode.light);

    await r.pressKey(LogicalKeyboardKey.arrowRight);
    expect(r.settings.themeMode, ThemeMode.dark);

    await r.pressKey(LogicalKeyboardKey.arrowRight);
    expect(r.settings.themeMode, ThemeMode.dark, reason: 'clamped at the end');

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();
    expect(r.settings.themeMode, ThemeMode.light);

    expect(focusInside(tester, find.byType(ThemeModeSelector)), isTrue);
  });

  testWidgets('confirm cycles the segments and wraps', (tester) async {
    final r = await focusThemeMode(tester);

    r.settings.themeMode = ThemeMode.dark;
    await tester.pumpAndSettle();

    r.sendInputAction(confirm);
    await tester.pumpAndSettle();

    expect(r.settings.themeMode, ThemeMode.system);
  });
}
