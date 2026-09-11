import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_screen.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

Map<String, Object> _settingsWithRecentRom() => {
  'recentRoms': [
    {
      'file': {
        'path': '/test/roms/nestest.nes',
        'name': '/test/roms/nestest.nes',
        'type': 'file',
      },
    },
  ],
};

Future<void> _navigateToEditor(Robot robot) async {
  robot.container.read(routerProvider).navigate(const SettingsRoute());
  await robot.tester.pumpAndSettle();

  await robot.settingsScreen.openCategory(SettingsCategory.video);
  await robot.settingsScreen.tapEditPalette();
}

Future<Robot> _openEditor(WidgetTester tester) async {
  final robot = Robot(tester);

  await robot.pumpApp();
  await _navigateToEditor(robot);

  return robot;
}

void main() {
  testWidgets('leaving a clean editor drops the draft and restores the '
      'selected palette', (tester) async {
    final robot = await _openEditor(tester);

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(PaletteEditorScreen), findsNothing);
    expect(robot.container.read(paletteEditorProvider), isNull);
    expect(
      robot.container.read(nesPaletteProvider),
      equals(expandRgbToPalette(defaultPaletteRgb)),
    );
  });

  testWidgets('leaving with unsaved edits asks before discarding', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);
    await tester.pumpAndSettle();

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(PaletteEditorScreen), findsOneWidget);
    expect(find.byType(ConfirmationDialog), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(PaletteEditorScreen), findsNothing);

    expect(
      robot.container.read(nesPaletteProvider),
      equals(expandRgbToPalette(defaultPaletteRgb)),
    );
    expect(robot.container.read(paletteEditorProvider), isNull);
  });

  testWidgets('declining the discard leaves the screen and draft intact', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);
    await tester.pumpAndSettle();

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsNothing);
    expect(find.byType(PaletteEditorScreen), findsOneWidget);

    final state = robot.container.read(paletteEditorProvider);

    expect(state, isNotNull);
    expect(state!.dirty, isTrue);
    expect(state.colors[0], equals(0x102030));
  });

  testWidgets('leaving after a successful save exits without prompting', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaletteEditorScreen.saveKey));
    await robot.waitUntil(
      () => robot.container.read(paletteEditorProvider)?.dirty == false,
    );
    await tester.pumpAndSettle();

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialog), findsNothing);
    expect(find.byType(PaletteEditorScreen), findsNothing);
    expect(robot.container.read(paletteEditorProvider), isNull);
  });

  testWidgets('navigating away declaratively drops the draft', (tester) async {
    final robot = Robot(tester)..initSettings(_settingsWithRecentRom());

    await robot.pumpApp();
    await robot.mainMenu.tapFirstRomTile();
    await _navigateToEditor(robot);

    robot.container.read(paletteEditorProvider.notifier).setColor(0, 0x102030);
    await tester.pumpAndSettle();

    robot.container.read(routerProvider).navigate(const EmulatorRoute());
    await robot.waitUntil(
      () => find.byType(PaletteEditorScreen).evaluate().isEmpty,
    );

    expect(robot.container.read(paletteEditorProvider), isNull);
    expect(
      robot.container.read(nesPaletteProvider),
      equals(expandRgbToPalette(defaultPaletteRgb)),
    );

    await robot.emulator.tapMenu();
    await robot.menuScreen.tapQuitGame();
    await robot.waitUntil(() => robot.container.read(nesStateProvider) == null);
  });

  testWidgets('opening the screen without a draft builds without throwing', (
    tester,
  ) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const PaletteEditorRoute());
    await tester.pumpAndSettle();

    expect(find.byType(PaletteEditorScreen), findsOneWidget);
    expect(robot.container.read(paletteEditorProvider), isNull);
  });
}
