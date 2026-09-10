import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

Future<Robot> _openEditor(WidgetTester tester) async {
  final robot = Robot(tester);

  await robot.pumpApp();

  robot.container.read(routerProvider).navigate(const SettingsRoute());
  await tester.pumpAndSettle();

  await robot.settingsScreen.openCategory(SettingsCategory.video);
  await robot.settingsScreen.tapEditPalette();

  return robot;
}

PaletteEditorState _state(Robot robot) =>
    robot.container.read(paletteEditorProvider)!;

Future<void> _pressUndo(WidgetTester tester) async {
  await tester.tap(find.byKey(PaletteEditorScreen.undoKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('undo and redo start disabled on a fresh draft', (tester) async {
    await _openEditor(tester);

    expect(
      tester
          .widget<IconButton>(find.byKey(PaletteEditorScreen.undoKey))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(PaletteEditorScreen.redoKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets('undo takes back an edit and redo puts it back', (tester) async {
    final robot = await _openEditor(tester);

    final before = _state(robot).colors[0];

    robot.container
        .read(paletteEditorProvider.notifier)
        .setColor(0, 0x102030, source: const EditSource.hex(0));
    await tester.pumpAndSettle();

    await _pressUndo(tester);

    expect(_state(robot).colors[0], equals(before));

    await tester.tap(find.byKey(PaletteEditorScreen.redoKey));
    await tester.pumpAndSettle();

    expect(_state(robot).colors[0], equals(0x102030));
  });

  testWidgets('reset restores every colour but keeps the name', (tester) async {
    final robot = await _openEditor(tester);

    final before = _state(robot).colors[0];
    final notifier = robot.container.read(paletteEditorProvider.notifier)
      ..setColor(0, 0x102030, source: const EditSource.hex(0))
      ..setName('Something else');

    await tester.pumpAndSettle();

    final reset = find.byKey(PaletteEditorScreen.resetKey);

    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(_state(robot).colors[0], equals(before));
    expect(_state(robot).name, equals('Something else'));

    notifier.undo();

    expect(_state(robot).colors[0], equals(0x102030));
  });

  testWidgets('the undo shortcut takes back an edit', (tester) async {
    final robot = await _openEditor(tester);

    final before = _state(robot).colors[0];

    robot.container
        .read(paletteEditorProvider.notifier)
        .setColor(0, 0x102030, source: const EditSource.hex(0));
    await tester.pumpAndSettle();

    await robot.expectAndFocus(find.byKey(PaletteSwatchGrid.swatchKey(0)));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(_state(robot).colors[0], equals(before));
  });

  testWidgets('the undo shortcut leaves the hex field to its own undo', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container
        .read(paletteEditorProvider.notifier)
        .setColor(0, 0x102030, source: const EditSource.hex(0));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteColorEditor.hexKey));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(_state(robot).colors[0], equals(0x102030));
  });
}
