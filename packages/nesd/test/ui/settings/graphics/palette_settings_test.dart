import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/graphics/palette_import_button.dart';
import 'package:nesd/ui/settings/graphics/palette_preview.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:riverpod/misc.dart';

import '../../../helpers/fake_platform_file.dart';
import '../../../helpers/pal_file.dart';
import '../settings_robot.dart';

Override _pickerReturning(PlatformFile? file) => palettePickerProvider
    .overrideWithValue(({required type, allowedExtensions}) async => file);

FakePlatformFile _palFileNamed(String name, Uint8List bytes) =>
    FakePlatformFile(name: name, path: '', bytes: bytes);

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

  testWidgets('importing a .pal file adds it, selects it and applies it', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen(
      overrides: [
        _pickerReturning(_palFileNamed('Grey.pal', greyPalFile(0x40))),
      ],
    );
    robot.container.listen(toasterProvider, (_, _) {});
    await robot.tapGraphicsTab();
    await robot.tapImportPalette();

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(const UserPaletteSelection('Grey')),
    );
    expect(
      robot.container.read(nesPaletteProvider)[0],
      equals(packPaletteColor(0x40, 0x40, 0x40)),
    );
    expect(find.text('Grey'), findsOneWidget);
    expect(find.text('Remove palette'), findsOneWidget);

    final toasts = robot.container.read(toastStateProvider);

    expect(toasts.single.type, equals(ToastType.info));
    expect(toasts.single.message, equals('Imported Grey'));
  });

  testWidgets('a wrong-sized file is rejected with an error toast', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen(
      overrides: [_pickerReturning(_palFileNamed('Bad.pal', Uint8List(7)))],
    );
    robot.container.listen(toasterProvider, (_, _) {});
    await robot.tapGraphicsTab();
    await robot.tapImportPalette();

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(PaletteSelection.defaultSelection),
    );
    expect(find.text('Bad'), findsNothing);

    final toasts = robot.container.read(toastStateProvider);

    expect(toasts.single.type, equals(ToastType.error));
    expect(toasts.single.message, startsWith('Could not import Bad:'));
  });

  testWidgets('cancelling the dialog changes nothing', (tester) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen(overrides: [_pickerReturning(null)]);
    await robot.tapGraphicsTab();
    await robot.tapImportPalette();

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(PaletteSelection.defaultSelection),
    );
    expect(robot.container.read(toastStateProvider), isEmpty);
  });

  testWidgets('removing the selected user palette returns to Default', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen(
      overrides: [
        _pickerReturning(_palFileNamed('Grey.pal', greyPalFile(0x40))),
      ],
    );
    robot.container.listen(toasterProvider, (_, _) {});
    await robot.tapGraphicsTab();
    await robot.tapImportPalette();
    await robot.tapRemovePalette();

    expect(
      robot.container.read(settingsControllerProvider).paletteSelection,
      equals(PaletteSelection.defaultSelection),
    );
    expect(find.text('Grey'), findsNothing);
    expect(find.text('Remove palette'), findsNothing);
    expect(robot.container.read(userPalettesProvider).requireValue, isEmpty);
  });

  testWidgets('the remove button is hidden for built-in palettes', (
    tester,
  ) async {
    final robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen();
    await robot.tapGraphicsTab();

    expect(find.byType(PaletteImportButton), findsOneWidget);
    expect(find.text('Remove palette'), findsNothing);

    await robot.selectPalette(NesPaletteId.warm);

    expect(find.text('Remove palette'), findsNothing);
  });
}
