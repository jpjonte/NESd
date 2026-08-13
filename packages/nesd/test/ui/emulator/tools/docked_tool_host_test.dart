import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tile_debug.dart';
import 'package:nesd/ui/emulator/tools/display_tool.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';

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

  testWidgets('renders the execution log inside the column', (tester) async {
    final r = await start(tester, ['debugger', 'executionLog']);

    expect(find.byType(ExecutionLogWidget), findsOneWidget);
    expect(find.byType(DebuggerWidget), findsOneWidget);

    expect(tester.takeException(), isNull);

    await quit(r);
  });

  testWidgets('renders exactly the open tools in registry order', (
    tester,
  ) async {
    final r = await start(tester, [
      'executionLog',
      'debugger',
      'cartridgeInfo',
    ]);

    expect(find.byType(TileDebugWidget), findsNothing);
    expect(find.byType(ApuDebugWidget), findsNothing);

    final cartridgeInfoTop = tester
        .getTopLeft(find.byType(CartridgeInfoWidget))
        .dy;
    final debuggerTop = tester.getTopLeft(find.byType(DebuggerWidget)).dy;
    final executionLogTop = tester
        .getTopLeft(find.byType(ExecutionLogWidget))
        .dy;

    expect(cartridgeInfoTop, lessThan(debuggerTop));
    expect(debuggerTop, lessThan(executionLogTop));

    expect(tester.takeException(), isNull);

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

  testWidgets('all five tools lay out without overflowing', (tester) async {
    final r = await start(tester, [
      'tileViewer',
      'cartridgeInfo',
      'debugger',
      'apuDebug',
      'executionLog',
    ]);

    tester.view.physicalSize =
        const Size(1920, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pump();

    expect(tester.takeException(), isNull);

    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    await tester.pump();

    await quit(r);
  });

  testWidgets('tools still expand to fill when they fit', (tester) async {
    final r = await start(tester, ['debugger', 'apuDebug']);

    final height = tester.getSize(find.byType(DebuggerWidget)).height;

    expect(height, greaterThan(EmulatorTool.debugger.minHeight));

    await quit(r);
  });

  testWidgets('cartridge info fits its registered minHeight', (tester) async {
    final r = await start(tester, ['cartridgeInfo']);

    expect(
      tester.getSize(find.byType(CartridgeInfoWidget)).height,
      lessThanOrEqualTo(EmulatorTool.cartridgeInfo.minHeight),
    );

    await quit(r);
  });

  testWidgets('tools are pinned and scrollable when they do not fit', (
    tester,
  ) async {
    final r = await start(tester, [
      'tileViewer',
      'cartridgeInfo',
      'debugger',
      'apuDebug',
      'executionLog',
    ]);

    expect(
      tester.getSize(find.byType(DebuggerWidget)).height,
      EmulatorTool.debugger.minHeight,
    );

    final column = find
        .descendant(
          of: find.byType(DockedToolHost),
          matching: find.byType(Scrollable),
        )
        .first;

    expect(
      tester.state<ScrollableState>(column).position.maxScrollExtent,
      greaterThan(0),
    );

    await quit(r);
  });

  testWidgets('display tool renders in the docked column', (tester) async {
    final r = await start(tester, ['display']);

    expect(find.byType(DockedToolHost), findsOneWidget);
    expect(find.byType(DisplayToolWidget), findsOneWidget);

    await quit(r);
  });
}
