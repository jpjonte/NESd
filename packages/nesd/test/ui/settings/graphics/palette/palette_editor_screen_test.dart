import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_edit_button.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

void main() {
  testWidgets('editing a built-in palette forks it under a copy name', (
    tester,
  ) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const SettingsRoute());
    await tester.pumpAndSettle();

    await robot.settingsScreen.openCategory(SettingsCategory.video);

    final resolved = paletteBaseColors(
      robot.container.read(nesPaletteProvider),
    );

    await robot.settingsScreen.tapEditPalette();

    expect(find.byType(PaletteEditorScreen), findsOneWidget);
    expect(find.byType(PaletteSwatchGrid), findsOneWidget);

    final state = robot.container.read(paletteEditorProvider)!;

    expect(state.name, equals('Default copy'));
    expect(state.colors, equals(resolved));
    expect(state.dirty, isFalse);
  });

  testWidgets('tapping a swatch selects it', (tester) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const SettingsRoute());
    await tester.pumpAndSettle();

    await robot.settingsScreen.openCategory(SettingsCategory.video);
    await robot.settingsScreen.tapEditPalette();

    await tester.tap(find.byKey(PaletteSwatchGrid.swatchKey(5)));
    await tester.pumpAndSettle();

    expect(robot.container.read(paletteEditorProvider)!.selected, equals(5));
  });

  test('fork names avoid collisions', () {
    expect(paletteForkName('Default', const []), equals('Default copy'));
    expect(
      paletteForkName('Default', const ['Default copy']),
      equals('Default copy 2'),
    );
    expect(
      paletteForkName('Default', const ['Default copy', 'Default copy 2']),
      equals('Default copy 3'),
    );
  });
}
