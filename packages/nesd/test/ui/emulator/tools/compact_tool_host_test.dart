import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/compact_tool_host.dart';
import 'package:nesd/ui/emulator/tools/display_tool.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';

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
  Future<Robot> start(
    WidgetTester tester,
    List<String> openTools, {
    Size size = const Size(360, 800),
  }) async {
    final r = Robot(tester)..initSettings({..._rom, 'openTools': openTools});

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();

    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pump();

    return r;
  }

  Future<void> quit(Robot r, WidgetTester tester) async {
    // Widen back to the same size pumpApp() uses rather than
    // resetPhysicalSize(): the headless test binding's native size is
    // 800x600, still below dockedToolsMinWidth, which would leave the
    // compact host (and any tool still open) covering the emulator's own
    // menu button. Widening to exactly dockedToolsMinWidth isn't enough
    // either — a docked column plus the execution log side by side can
    // together exceed it.
    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;
    await tester.pump();

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  }

  for (final tool in EmulatorTool.values) {
    testWidgets('${tool.name} lays out at 360x800 without overflowing', (
      tester,
    ) async {
      final r = await start(tester, [tool.name]);

      expect(tester.takeException(), isNull);
      expect(find.byType(CompactToolHost), findsOneWidget);

      await quit(r, tester);
    });
  }

  testWidgets('the tab strip switches the visible tool', (tester) async {
    final r = await start(tester, ['debugger', 'executionLog']);

    expect(tester.takeException(), isNull);
    expect(find.byType(DebuggerWidget), findsOneWidget);
    expect(find.byType(ExecutionLogWidget), findsNothing);

    await tester.tap(find.byKey(const Key('compactTab_executionLog')));
    await tester.pump();

    expect(find.byType(ExecutionLogWidget), findsOneWidget);
    expect(find.byType(DebuggerWidget), findsNothing);
    expect(tester.takeException(), isNull);

    await quit(r, tester);
  });

  testWidgets('closing the active tool falls back to another open one', (
    tester,
  ) async {
    final r = await start(tester, ['debugger', 'executionLog']);

    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('compactToolClose')));
    await tester.pump();

    expect(r.container.read(emulatorToolsControllerProvider), {
      EmulatorTool.executionLog,
    });
    expect(find.byType(ExecutionLogWidget), findsOneWidget);
    expect(tester.takeException(), isNull);

    await quit(r, tester);
  });

  testWidgets('display tool shows as a compact tab with its panel', (
    tester,
  ) async {
    final r = await start(tester, ['display']);

    expect(find.byKey(const Key('compactTab_display')), findsOneWidget);
    expect(find.byType(DisplayToolWidget), findsOneWidget);

    await quit(r, tester);
  });

  testWidgets('the host swaps at the breakpoint', (tester) async {
    final r = await start(tester, [
      'debugger',
    ], size: const Size(dockedToolsMinWidth - 1, 800));

    expect(find.byType(CompactToolHost), findsOneWidget);
    expect(find.byType(DockedToolHost), findsNothing);

    tester.view.physicalSize =
        const Size(dockedToolsMinWidth, 800) * tester.view.devicePixelRatio;
    await tester.pump();

    expect(find.byType(DockedToolHost), findsOneWidget);
    expect(find.byType(CompactToolHost), findsNothing);

    await quit(r, tester);
  });
}
