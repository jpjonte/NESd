import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_frame_preview.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../../robot.dart';

class _FakeEmulator {
  int requests = 0;

  Future<RepaintFrameResponse?> repaint(Uint32List palette) async {
    requests++;

    final pixels = Uint32List(8 * 8)..fillRange(0, 8 * 8, palette[0x21]);

    return RepaintFrameResponse(
      requestId: requests,
      pixels: NesBytes.fromList([pixels]),
      width: 8,
      height: 8,
    );
  }
}

Future<Robot> _openEditor(WidgetTester tester, {RepaintFrame? repaint}) async {
  final robot = Robot(tester);

  await robot.pumpApp(
    overrides: [paletteRepaintProvider.overrideWithValue(repaint)],
  );

  robot.container.read(routerProvider).navigate(const SettingsRoute());
  await tester.pumpAndSettle();

  await robot.settingsScreen.openCategory(SettingsCategory.video);
  await robot.settingsScreen.tapEditPalette();

  return robot;
}

Finder get _previewImage => find.byKey(PaletteFramePreview.imageKey);

ui.Image? _renderedImage(WidgetTester tester) =>
    tester.widget<RawImage>(_previewImage).image;

Future<int> _topLeftPixel(WidgetTester tester) async {
  final bytes = await tester.runAsync(
    () => _renderedImage(tester)!.toByteData(),
  );

  return bytes!.getUint32(0);
}

void main() {
  testWidgets('shows no preview when no emulator can supply a frame', (
    tester,
  ) async {
    final robot = await _openEditor(tester);

    await robot.fixAsync();

    expect(_previewImage, findsNothing);
  });

  testWidgets('draws the emulator frame through the palette being edited', (
    tester,
  ) async {
    final emulator = _FakeEmulator();

    final robot = await _openEditor(tester, repaint: emulator.repaint);

    await robot.waitUntil(() => _previewImage.evaluate().isNotEmpty);

    expect(await _topLeftPixel(tester), isNot(equals(0x102030ff)));
  });

  testWidgets('asks for a repaint when a colour of the draft changes', (
    tester,
  ) async {
    final emulator = _FakeEmulator();

    final robot = await _openEditor(tester, repaint: emulator.repaint);

    await robot.waitUntil(() => _previewImage.evaluate().isNotEmpty);

    final before = _renderedImage(tester);

    robot.container
        .read(paletteEditorProvider.notifier)
        .setColor(0x21, 0x102030);

    await robot.waitUntil(() => _renderedImage(tester) != before);

    expect(await _topLeftPixel(tester), equals(0x102030ff));
  });

  testWidgets('fits the preview and every slider on a wide window', (
    tester,
  ) async {
    final emulator = _FakeEmulator();

    final robot = await _openEditor(tester, repaint: emulator.repaint);

    await robot.waitUntil(() => _previewImage.evaluate().isNotEmpty);

    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    final preview = tester.getRect(_previewImage);

    expect(preview.bottom, lessThanOrEqualTo(height));

    expect(preview.height, greaterThan(height / 3));

    expect(
      tester.getRect(find.byKey(PaletteColorEditor.channelKey(2))).bottom,
      lessThanOrEqualTo(height),
    );
  });
}
