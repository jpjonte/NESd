import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/general/auto_save_interval.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

void main() {
  final tile = find.byType(AutoSaveInterval);
  final field = find.descendant(of: tile, matching: find.byType(TextField));

  Future<Robot> focusTile(WidgetTester tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();

    focusInto(tester, tile);
    await tester.pumpAndSettle();

    return r;
  }

  testWidgets('left and right step the interval', (tester) async {
    final r = await focusTile(tester);

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();
    expect(r.settings.autoSaveInterval, 2);

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();
    expect(r.settings.autoSaveInterval, 1);
  });

  testWidgets('rapid right presses each step from the live value', (
    tester,
  ) async {
    final r = await focusTile(tester);

    expect(r.settings.autoSaveInterval, 1);

    r.sendInputAction(inputRight);
    await tester.pump();
    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.settings.autoSaveInterval, 3);
  });

  testWidgets('stepping updates the visible number', (tester) async {
    final r = await focusTile(tester);

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller?.text, '2');
  });

  testWidgets('confirm enters the field and confirm leaves it', (tester) async {
    final r = await focusTile(tester);

    expect(focusInside(tester, field), isFalse);

    r.sendInputAction(confirm);
    await tester.pumpAndSettle();
    expect(focusInside(tester, field), isTrue);

    r.sendInputAction(confirm);
    await tester.pumpAndSettle();
    expect(focusInside(tester, field), isFalse);
    expect(focusInside(tester, tile), isTrue);
  });

  testWidgets('down leaves the field for the next tile', (tester) async {
    final r = await focusTile(tester);

    r.sendInputAction(confirm);
    await tester.pumpAndSettle();

    r.sendInputAction(nextInput);
    await tester.pumpAndSettle();

    expect(focusInside(tester, tile), isFalse);
  });
}
