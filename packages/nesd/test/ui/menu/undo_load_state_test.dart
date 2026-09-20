import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/menu/menu_screen.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../robot.dart';

Robot _robot(WidgetTester tester) => Robot(tester)
  ..initSettings({
    'recentRoms': [
      {
        'file': {
          'path': '/test/roms/nestest.nes',
          'name': '/test/roms/nestest.nes',
          'type': 'file',
        },
      },
    ],
  });

Future<void> _startGame(Robot r) async {
  await r.pumpApp(storage: MemoryStorageFilesystem());
  await r.mainMenu.tapFirstRomTile();

  r.emulator.expectEmulatorWidgetFound();

  await r.pumpFrames(const Duration(seconds: 2));
}

Future<void> _quitGame(Robot r) async {
  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

Future<void> _saveAndLoadSlot1(Robot r) async {
  final controller = r.container.read(nesControllerProvider);

  await r.tester.runAsync(() async {
    await controller.saveState(1);
    await controller.loadState(1);
  });

  await r.waitUntil(() => r.container.read(nesStateProvider)!.canUndoLoadState);
}

void main() {
  testWidgets('the undo entry is hidden until a state is loaded', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await r.emulator.tapMenu();

    expect(find.byKey(MenuScreen.undoLoadStateKey), findsNothing);

    await r.menuScreen.tapResume();
    await _quitGame(r);
  });

  testWidgets('the undo entry restores the position and returns to the game', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await _saveAndLoadSlot1(r);

    await r.emulator.tapMenu();

    await r.menuScreen.tapUndoLoadState();
    await r.waitUntil(() => find.byType(MenuScreen).evaluate().isEmpty);

    r.emulator.expectEmulatorWidgetFound();
    expect(
      r.container.read(toastStateProvider).map((toast) => toast.message),
      contains('Load state undone'),
    );
    expect(
      r.isolateHandles.last.sentCommands.whereType<UndoLoadStateCommand>(),
      hasLength(1),
    );

    await _quitGame(r);
  });
}
