import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
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

void main() {
  testWidgets('typing a hex value updates the colour and the live palette', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    await tester.enterText(find.byKey(PaletteColorEditor.hexKey), '#102030');
    await tester.pumpAndSettle();

    expect(
      robot.container.read(paletteEditorProvider)!.colors[0],
      equals(0x102030),
    );
    expect(
      robot.container.read(nesPaletteProvider)[0],
      equals(packPaletteColor(0x10, 0x20, 0x30)),
    );
  });

  testWidgets('a half-typed hex value leaves the colour alone', (tester) async {
    final robot = await _openEditor(tester);

    final before = robot.container.read(paletteEditorProvider)!.colors[0];

    await tester.enterText(find.byKey(PaletteColorEditor.hexKey), '#10');
    await tester.pumpAndSettle();

    expect(
      robot.container.read(paletteEditorProvider)!.colors[0],
      equals(before),
    );
  });

  testWidgets('dragging the red slider changes only the red channel', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x808080);
    await tester.pumpAndSettle();

    await tester.drag(
      find.descendant(
        of: find.byKey(PaletteColorEditor.channelKey(0)),
        matching: find.byType(Slider),
      ),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    final color = robot.container.read(paletteEditorProvider)!.colors[0];

    expect(color & 0xffff, equals(0x8080));
    expect((color >> 16) & 0xff, greaterThan(0x80));
  });
}
