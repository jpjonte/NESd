import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_actions.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

class _RecordingPaletteActions implements PaletteActions {
  String? name;
  Uint8List? bytes;

  @override
  Future<Uri?> exportPalette(String name, List<int> rgb) async {
    this.name = name;
    bytes = writePalFile(rgb);

    return Uri.parse('file:///tmp/$name.pal');
  }
}

void main() {
  testWidgets('export hands the current draft to the save dialog', (
    tester,
  ) async {
    final actions = _RecordingPaletteActions();
    final robot = Robot(tester);

    await robot.pumpApp(
      overrides: [paletteActionsProvider.overrideWithValue(actions)],
    );

    robot.container.read(routerProvider).navigate(const SettingsRoute());
    await tester.pumpAndSettle();

    await robot.settingsScreen.openCategory(SettingsCategory.video);
    await robot.settingsScreen.tapEditPalette();

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);

    await tester.tap(find.byKey(PaletteEditorScreen.exportKey));
    await robot.waitUntil(() => actions.bytes != null);

    expect(actions.name, equals('Default copy'));
    expect(actions.bytes, hasLength(192));
    expect(
      parsePalFile(actions.bytes!)[0],
      equals(packPaletteColor(0x10, 0x20, 0x30)),
    );
  });
}
