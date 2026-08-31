import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/graphics/palette_preview.dart';

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
}
