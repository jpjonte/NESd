@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/robot.dart';

const _graphics =
    'android/app/src/main/play/listings/en-US/graphics/phone-screenshots';

const _logicalSize = Size(360, 800);
const _pixelRatio = 3.0;

Future<Robot> _phoneApp(
  WidgetTester tester, {
  Map<String, Uint8List> extraFiles = const {},
}) async {
  final robot = Robot(tester);

  await robot.pumpApp(
    extraFiles: extraFiles,
    logicalSize: _logicalSize,
    devicePixelRatio: _pixelRatio,
  );

  return robot;
}

Future<void> _capture(Robot robot, String name) async {
  Directory(_graphics).createSync(recursive: true);

  await robot.screenshot('$_graphics/$name.png', pixelRatio: _pixelRatio);
}

void main() {
  testWidgets('01_main_menu', (tester) async {
    final r = await _phoneApp(tester);

    await tester.pumpAndSettle();

    await r.waitUntil(() {
      final images = tester.widgetList<RawImage>(find.byType(RawImage));

      return images.isNotEmpty && images.every((image) => image.image != null);
    });

    r.mainMenu.expectLogoFound();

    await _capture(r, '01_main_menu');
  });

  testWidgets('02_library', (tester) async {
    final r = await _phoneApp(tester);

    r.settings.lastRomPath = const FilesystemFile(
      path: '/test/roms',
      name: '/test/roms',
      type: FilesystemFileType.directory,
    );

    await r.mainMenu.tapOpenRomButton();
    await tester.pumpAndSettle();

    await _capture(r, '02_library');
  });

  testWidgets('03_settings', (tester) async {
    final r = await _phoneApp(tester);

    await r.mainMenu.tapSettingsButton();
    await tester.pumpAndSettle();

    await _capture(r, '03_settings');
  });

  testWidgets('04_touch_controls', (tester) async {
    final r = await _phoneApp(tester);

    r.settings.showTouchControls = true;

    await r.settings.resetTouchInputConfigs(Orientation.portrait);

    await tester.pumpAndSettle();

    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();

    tester.takeException();

    await r.settingsScreen.controls.tapTouchEditorButton();
    await tester.pumpAndSettle();

    await r.waitUntil(() => find.byType(DisplayBuilder).evaluate().isNotEmpty);

    await _capture(r, '04_touch_controls');
  });
}
