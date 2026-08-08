import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tile_debug.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';

import '../../robot.dart';

const _rom = {
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

void main() {
  Future<Robot> start(WidgetTester tester, List<String> openTools) async {
    final r = Robot(tester)..initSettings({..._rom, 'openTools': openTools});

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    return r;
  }

  Future<void> quit(Robot r) async {
    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  }

  testWidgets('renders only the open tools', (tester) async {
    final r = await start(tester, ['debugger', 'cartridgeInfo']);

    expect(find.byType(DebuggerWidget), findsOneWidget);
    expect(find.byType(CartridgeInfoWidget), findsOneWidget);
    expect(find.byType(TileDebugWidget), findsNothing);
    expect(find.byType(ApuDebugWidget), findsNothing);
    expect(find.byType(ExecutionLogWidget), findsNothing);

    await quit(r);
  });

  testWidgets('renders nothing when no tool is open', (tester) async {
    final r = await start(tester, []);

    expect(find.byType(DockedToolHost), findsOneWidget);
    expect(find.byType(DebuggerWidget), findsNothing);
    expect(find.byType(TileDebugWidget), findsNothing);

    await quit(r);
  });

  testWidgets('renders the execution log beside the column', (tester) async {
    final r = await start(tester, ['debugger', 'executionLog']);

    expect(find.byType(ExecutionLogWidget), findsOneWidget);
    expect(find.byType(DebuggerWidget), findsOneWidget);

    await quit(r);
  });

  testWidgets('omits cartridge info when the session has none', (tester) async {
    final r = await start(tester, ['debugger', 'cartridgeInfo']);

    expect(find.byType(CartridgeInfoWidget), findsOneWidget);
    expect(find.byType(DebuggerWidget), findsOneWidget);

    unawaited(r.container.read(nesControllerProvider).stop());

    await r.waitUntil(() => r.container.read(nesStateProvider) == null);

    expect(find.byType(DockedToolHost), findsOneWidget);
    expect(find.byType(CartridgeInfoWidget), findsNothing);
    expect(find.byType(DebuggerWidget), findsOneWidget);
  });
}
