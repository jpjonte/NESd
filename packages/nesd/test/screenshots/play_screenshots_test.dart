@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../ui/robot.dart';

const _graphics =
    'android/app/src/main/play/listings/en-US/graphics/phone-screenshots';

const _logicalSize = Size(360, 800);
const _pixelRatio = 3.0;

Future<Robot> _phoneApp(
  WidgetTester tester, {
  Size size = _logicalSize,
  Map<String, Uint8List> extraFiles = const {},
}) async {
  final robot = Robot(tester);

  await robot.pumpApp(
    extraFiles: extraFiles,
    logicalSize: size,
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

  testWidgets('05_library', (tester) async {
    final r = await _phoneApp(tester);

    r.settings.lastRomPath = const FilesystemFile(
      path: '/test/roms',
      name: '/test/roms',
      type: FilesystemFileType.directory,
    );

    await r.mainMenu.tapOpenRomButton();
    await tester.pumpAndSettle();

    await _capture(r, '05_library');
  });

  testWidgets('04_settings', (tester) async {
    final r = await _phoneApp(tester);

    r.showFocusHighlights();

    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.focusFirstCategory();

    await _capture(r, '04_settings');
  });

  testWidgets('02_touch_controls_narrow', (tester) async {
    final r = await _phoneApp(tester);

    r.settings.showTouchControls = true;

    await r.settings.resetTouchInputConfigs(Orientation.portrait);

    await tester.pumpAndSettle();

    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    tester.takeException();

    await r.settingsScreen.controls.tapTouchEditorButton();
    await tester.pumpAndSettle();

    await r.waitUntil(() => find.byType(DisplayBuilder).evaluate().isNotEmpty);

    await _capture(r, '02_touch_controls_narrow');
  });

  testWidgets('03_touch_controls_wide', (tester) async {
    final r = await _phoneApp(tester, size: _logicalSize.flipped);

    r.settings.showTouchControls = true;

    await r.settings.resetTouchInputConfigs(Orientation.landscape);

    await tester.pumpAndSettle();

    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    tester.takeException();

    await r.settingsScreen.controls.tapTouchEditorButton();
    await tester.pumpAndSettle();

    await r.waitUntil(() => find.byType(DisplayBuilder).evaluate().isNotEmpty);

    await _capture(r, '03_touch_controls_wide');
  });
}
