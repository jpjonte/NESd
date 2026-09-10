import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

Uint8List _fullPalFileWithCustomEmphasis() {
  final bytes = Uint8List(1536);

  for (var i = 0; i < 512; i++) {
    final offset = i * 3;

    bytes[offset] = i < 64 ? 0x40 : 0x11;
    bytes[offset + 1] = i < 64 ? 0x40 : 0x22;
    bytes[offset + 2] = i < 64 ? 0x40 : 0x33;
  }

  return bytes;
}

void main() {
  testWidgets('a palette with hand-authored emphasis warns in the editor', (
    tester,
  ) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    await robot.container
        .read(userPalettesProvider.notifier)
        .import('Full', _fullPalFileWithCustomEmphasis());

    robot.container.read(routerProvider).navigate(const SettingsRoute());
    await tester.pumpAndSettle();

    await robot.settingsScreen.openCategory(SettingsCategory.video);
    await robot.settingsScreen.selectUserPalette('Full');
    await robot.settingsScreen.tapEditPalette();

    expect(find.byKey(PaletteEditorScreen.emphasisWarningKey), findsOneWidget);
  });

  testWidgets('a generated palette shows no warning', (tester) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const SettingsRoute());
    await tester.pumpAndSettle();

    await robot.settingsScreen.openCategory(SettingsCategory.video);
    await robot.settingsScreen.tapEditPalette();

    expect(find.byKey(PaletteEditorScreen.emphasisWarningKey), findsNothing);
  });
}
