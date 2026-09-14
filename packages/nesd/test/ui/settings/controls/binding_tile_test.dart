import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/binding_tile.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../helpers/focus.dart';
import '../../robot.dart';

void main() {
  Future<(BindingTile, Finder)> openControlsTab(Robot r) async {
    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);
    await r.settingsScreen.expandBindingGroup('controls.bindings.menu');

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

  testWidgets('left and right no longer switch the profile', (tester) async {
    final r = Robot(tester);

    final (_, tileFinder) = await openControlsTab(r);

    focusInto(tester, tileFinder);
    await tester.pumpAndSettle();

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.container.read(profileIndexProvider), 0);
  });

  testWidgets('left and right flip hold and toggle on a toggleable action', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);
    await r.settingsScreen.expandBindingGroup('controls.bindings.player1');

    final tileFinder = find
        .byWidgetPredicate((w) => w is BindingTile && w.action.toggleable)
        .first;
    final action = tester.widget<BindingTile>(tileFinder).action;

    await tester.ensureVisible(tileFinder);
    focusInto(tester, tileFinder);
    await tester.pumpAndSettle();

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.settings.getBinding(action, 0)?.type, BindingType.toggle);

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();

    expect(r.settings.getBinding(action, 0)?.type, BindingType.hold);
  });

  testWidgets('Shift+Tab leaves the focused binding intact', (tester) async {
    final r = Robot(tester);

    final (tile, tileFinder) = await openControlsTab(r);

    focusInto(tester, tileFinder);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();

    expect(r.settings.getBinding(tile.action, 0), isNotNull);
    expect(
      r.container.read(settingsNavigationProvider.notifier).category,
      isNot(SettingsCategory.controls),
    );
  });

  testWidgets('the profile header switches profiles with left and right', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    focusInto(tester, find.byType(ProfileSelectionHeader));
    await tester.pumpAndSettle();

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.container.read(profileIndexProvider), 1);
  });
}
