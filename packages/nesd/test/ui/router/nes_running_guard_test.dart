import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/emulator_screen.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart' hide Router;

import '../robot.dart';

class _MockResolver extends Mock implements NavigationResolver {}

class _MockStackRouter extends Mock implements StackRouter {}

class _MockAutoRoutePage extends Mock implements AutoRoutePage<Object?> {}

const _romInfo = RomInfo(
  file: FilesystemFile(
    path: '/test/roms/nestest.nes',
    name: 'nestest.nes',
    type: FilesystemFileType.file,
  ),
);

void main() {
  group('onNavigation without a running game', () {
    late _MockResolver resolver;
    late _MockStackRouter stackRouter;
    late NesRunningGuard guard;

    setUpAll(() => registerFallbackValue(const MainRoute()));

    setUp(() {
      resolver = _MockResolver();
      stackRouter = _MockStackRouter();
      guard = NesRunningGuard(isNesRunning: () => false);
    });

    test('redirects to the main menu on an empty stack (web reload)', () {
      when(() => stackRouter.stack).thenReturn(const []);

      guard.onNavigation(resolver, stackRouter);

      final captured = verify(
        () => resolver.redirectUntil(captureAny()),
      ).captured;

      expect(captured.single, isA<MainRoute>());
      verifyNever(() => resolver.next(any()));
    });

    test('cancels the navigation when a stack already exists', () {
      when(() => stackRouter.stack).thenReturn([_MockAutoRoutePage()]);

      guard.onNavigation(resolver, stackRouter);

      verify(() => resolver.next(false)).called(1);
      verifyNever(() => resolver.redirectUntil(any()));
    });
  });

  testWidgets(
    'emulator routes redirect to the main menu when no game is running',
    (tester) async {
      final r = Robot(tester);

      await r.pumpApp();

      final router = r.container.read(routerProvider);

      // Web URL restoration can request these directly after a reload,
      // when the emulator state is gone.
      for (final route in [
        const EmulatorRoute(),
        const MenuRoute(),
        SaveStatesRoute(romInfo: _romInfo),
        const ToolsRoute(),
        CheatsRoute(romInfo: _romInfo),
      ]) {
        // Not awaited: a guarded navigation's future only resolves once
        // the redirect target settles.
        unawaited(router.navigate(route));
        await tester.pumpAndSettle();

        expect(
          find.text('Open ROM'),
          findsOneWidget,
          reason: '${route.routeName} should redirect to the main menu',
        );
      }
    },
  );

  testWidgets('the emulator route still opens with a running game', (
    tester,
  ) async {
    final r = Robot(tester)
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

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();

    expect(find.byType(EmulatorScreen), findsOneWidget);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
