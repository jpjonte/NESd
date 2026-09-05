import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/graphics/palette_preview.dart';
import 'package:nesd/ui/settings/settings.dart';

import '../../../helpers/pal_file.dart';
import '../settings_robot.dart';

void main() {
  testWidgets('graphics tab shows the palette dropdown and preview', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen();
    await robot.tapGraphicsTab();

    expect(find.byType(PaletteDropdown), findsOneWidget);
    expect(find.byType(PalettePreview), findsOneWidget);
  });

  testWidgets('ntsc sliders appear only for the generated palette', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen();
    await robot.tapGraphicsTab();

    expect(find.byType(HueSlider), findsNothing);

    await robot.selectPalette(NesPaletteId.generated);

    expect(find.byType(HueSlider), findsOneWidget);
    expect(find.byType(SaturationSlider), findsOneWidget);
    expect(find.byType(ContrastSlider), findsOneWidget);
    expect(find.byType(BrightnessSlider), findsOneWidget);
    expect(find.byType(GammaSlider), findsOneWidget);
  });

  testWidgets('the dropdown lists imported palettes after the built-ins '
      'and selects them', (tester) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen();
    await robot.tapGraphicsTab();

    final notifier = robot.container.read(userPalettesProvider.notifier);

    await notifier.import('Grey', greyPalFile(0x40));
    await notifier.import('zeta', greyPalFile(0x50));
    await notifier.import('Alpha', greyPalFile(0x60));
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<PaletteSelection>>(
      find.byType(DropdownButton<PaletteSelection>),
    );

    expect(
      dropdown.items!.map((item) => item.value),
      equals([
        const BuiltInPaletteSelection(NesPaletteId.defaultPalette),
        const BuiltInPaletteSelection(NesPaletteId.warm),
        const BuiltInPaletteSelection(NesPaletteId.cool),
        const BuiltInPaletteSelection(NesPaletteId.flat),
        const BuiltInPaletteSelection(NesPaletteId.generated),
        const UserPaletteSelection('Alpha'),
        const UserPaletteSelection('Grey'),
        const UserPaletteSelection('zeta'),
      ]),
    );

    await robot.selectUserPalette('Grey');

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(const UserPaletteSelection('Grey')),
    );

    await robot.selectPalette(NesPaletteId.warm);

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(const BuiltInPaletteSelection(NesPaletteId.warm)),
    );
  });
}
