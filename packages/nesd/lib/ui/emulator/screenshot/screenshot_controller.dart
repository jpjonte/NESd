import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/screenshot/display_capture.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_mode.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_writer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screenshot_controller.g.dart';

@riverpod
ScreenshotController screenshotController(Ref ref) => ScreenshotController(
  nesState: ref.watch(nesStateProvider.notifier),
  settingsController: ref.read(settingsControllerProvider.notifier),
  toaster: ref.watch(toasterProvider),
  writer: ref.watch(screenshotWriterProvider),
  displayCapture: ref.watch(displayCaptureProvider),
);

class ScreenshotController {
  ScreenshotController({
    required this.nesState,
    required this.settingsController,
    required this.toaster,
    required this.writer,
    required this.displayCapture,
    this.now = DateTime.now,
  });

  final NesState nesState;
  final SettingsController settingsController;
  final Toaster toaster;
  final ScreenshotWriter writer;
  final DisplayCapture displayCapture;
  final DateTime Function() now;

  Future<void> takeScreenshot() async {
    final nes = nesState.nes;

    if (nes == null) {
      return;
    }

    final fileName = screenshotFileName(nes.romInfo, now());

    try {
      final png = await _encode(nes, settingsController.screenshotMode);

      if (png == null) {
        toaster.send(Toast.error('Could not capture the screen'));

        return;
      }

      final location = await writer(fileName, png);

      toaster.send(Toast.info('Saved screenshot to $location'));
    } on Object catch (e, s) {
      log.video.error(
        'Failed to save screenshot $fileName',
        error: e,
        stackTrace: s,
      );

      toaster.send(Toast.error('Could not save screenshot'));
    }
  }

  Future<Uint8List?> _encode(RemoteNes nes, ScreenshotMode mode) async {
    if (mode == ScreenshotMode.displayed) {
      final displayed = await _encodeDisplayed();

      if (displayed != null) {
        return displayed;
      }
    }

    return await _encodeRaw(nes);
  }

  Future<Uint8List?> _encodeRaw(RemoteNes nes) async {
    final frame = await nes.requestThumbnail();

    if (frame == null) {
      return null;
    }

    return encodeFramePng(
      width: frame.width,
      height: frame.height,
      pixels: frame.pixels,
    );
  }

  Future<Uint8List?> _encodeDisplayed() async {
    final image = await displayCapture.capture();

    if (image == null) {
      return null;
    }

    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);

      return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }
}

Uint8List encodeFramePng({
  required int width,
  required int height,
  required Uint8List pixels,
}) {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  return img.encodePng(image);
}

final _timestampFormat = DateFormat('yyyy-MM-dd HH-mm-ss');

String screenshotFileName(RomInfo romInfo, DateTime time) {
  final stem = p
      .basenameWithoutExtension(
        romInfo.file.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_'),
      )
      .trim();

  final name = stem.isEmpty ? 'screenshot' : stem;

  return '$name ${_timestampFormat.format(time)}.png';
}
