import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

import '../robot.dart';

void main() {
  testWidgets(
    'all four side rail panels lay out without error at a comfortably '
    'tall window, and the APU panel stays scrollable',
    (tester) async {
      final r = Robot(tester)
        ..initSettings({
          'openTools': ['tileViewer', 'cartridgeInfo', 'debugger', 'apuDebug'],
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

      await r.pumpApp();
      await r.mainMenu.tapFirstRomTile();
      r.emulator.expectEmulatorWidgetFound();

      // Let a real frame land so the APU panel has data to render.
      await r.waitUntil(() => find.text('Pulse 1').evaluate().isNotEmpty);

      tester.view.physicalSize =
          const Size(900, 800) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pump();

      expect(tester.takeException(), isNull);

      final apuDebugBox =
          tester.renderObject(find.byType(ApuDebugWidget)) as RenderBox;

      expect(apuDebugBox.hasSize, isTrue);
      expect(apuDebugBox.size.height, greaterThan(0));

      final apuScrollableFinder = find.ancestor(
        of: find.byType(ApuDebugWidget),
        matching: find.byType(Scrollable),
      );

      expect(apuScrollableFinder, findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(
        apuScrollableFinder,
      );
      final position = scrollableState.position;

      expect(position.hasContentDimensions, isTrue);
      expect(position.viewportDimension, greaterThan(0));

      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(apuScrollableFinder, const Offset(0, -100));
      await tester.pump();

      expect(scrollableState.position.pixels, greaterThan(0));

      await r.emulator.tapMenu();
      await r.menuScreen.tapQuitGame();
      await r.waitUntil(() => r.container.read(nesStateProvider) == null);
    },
  );
}
