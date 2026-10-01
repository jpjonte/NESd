import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_drop_target.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../robot.dart';

const _center = [960.0, 540.0];

const _desktop = TargetPlatformVariant({TargetPlatform.macOS});

Future<void> _platformDrop(
  WidgetTester tester,
  String method, [
  Object? arguments,
]) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'desktop_drop',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );

  await tester.pump();
}

Future<void> _dropFiles(WidgetTester tester, List<String> paths) async {
  await _platformDrop(tester, 'entered', _center);
  await _platformDrop(tester, 'performOperation', paths);
}

Future<void> _quit(Robot r) async {
  unawaited(r.container.read(nesControllerProvider).stop());

  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

int _loadCount(Robot r) => r.isolateHandles
    .expand((handle) => handle.sentCommands)
    .whereType<LoadRomCommand>()
    .length;

void main() {
  final highlight = find.byKey(RomDropTarget.highlightKey);

  testWidgets('a drag over the main menu highlights it until it leaves', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();

    expect(highlight, findsNothing);

    await _platformDrop(tester, 'entered', _center);

    expect(highlight, findsOneWidget);

    await _platformDrop(tester, 'exited');

    expect(highlight, findsNothing);
  }, variant: _desktop);

  testWidgets('dropping a ROM on the main menu starts it', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    await _dropFiles(tester, ['/test/roms/nestest.nes']);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(highlight, findsNothing);
    expect(
      r.container.read(nesStateProvider)?.romInfo.file.path,
      '/test/roms/nestest.nes',
    );

    await _quit(r);
  }, variant: _desktop);

  testWidgets('dropping a ROM on the emulator swaps the game once', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/second.nes': File(
          '../../roms/test/nestest/nestest.nes',
        ).readAsBytesSync(),
      },
    );

    await _dropFiles(tester, ['/test/roms/nestest.nes']);
    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    final loadsBefore = _loadCount(r);

    await _dropFiles(tester, ['/test/roms/second.nes']);
    await r.waitUntil(
      () =>
          r.container.read(nesStateProvider)?.romInfo.file.path ==
          '/test/roms/second.nes',
    );

    expect(
      _loadCount(r) - loadsBefore,
      1,
      reason: 'the covered main menu must not open the drop as well',
    );

    await _quit(r);
  }, variant: _desktop);

  testWidgets('Android does not install a drop target', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    expect(find.byType(DropTarget), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
