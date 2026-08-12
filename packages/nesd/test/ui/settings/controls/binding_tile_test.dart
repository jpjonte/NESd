import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';

import '../../robot.dart';

void main() {
  Future<(BindingTile, Finder)> openControlsTab(Robot r) async {
    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();

    final tileFinder = find.byType(BindingTile).first;
    final tile = r.tester.widget<BindingTile>(tileFinder);

    return (tile, tileFinder);
  }

  FocusNode tileFocusNode(WidgetTester tester, Finder tileFinder) {
    final focusFinder = find
        .descendant(of: tileFinder, matching: find.byType(Focus))
        .first;

    return tester.widget<Focus>(focusFinder).focusNode!;
  }

  // The tap is delayed by the double-tap detector, so pump past its
  // timeout before asserting.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('tapped binder stays in editing mode without focus', (
    tester,
  ) async {
    final r = Robot(tester);

    final (tile, tileFinder) = await openControlsTab(r);

    await tapAndSettle(tester, tileFinder);

    expect(r.container.read(binderStateProvider(tile.action)).editing, isTrue);

    // Regression #251: rebuild-induced focus notifications used to cancel
    // editing right after the tap on touch devices (no hover, no focus).
    await tester.pump(const Duration(seconds: 1));

    expect(r.container.read(binderStateProvider(tile.action)).editing, isTrue);
  });

  testWidgets('losing focus cancels editing', (tester) async {
    final r = Robot(tester);

    final (tile, tileFinder) = await openControlsTab(r);

    tileFocusNode(tester, tileFinder).requestFocus();
    await tester.pumpAndSettle();

    await tapAndSettle(tester, tileFinder);

    expect(r.container.read(binderStateProvider(tile.action)).editing, isTrue);

    tileFocusNode(tester, find.byType(BindingTile).at(1)).requestFocus();
    await tester.pumpAndSettle();

    expect(r.container.read(binderStateProvider(tile.action)).editing, isFalse);
  });
}
