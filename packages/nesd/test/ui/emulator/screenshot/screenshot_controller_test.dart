import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/screenshot/display_capture.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_controller.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_mode.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

class _MockNesState extends Mock implements NesState {}

class _MockRemoteNes extends Mock implements RemoteNes {}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _FakeDisplayCapture extends DisplayCapture {
  const _FakeDisplayCapture(this.image);

  final ui.Image? image;

  @override
  Future<ui.Image?> capture() async => image;
}

const _romInfo = RomInfo(
  file: FilesystemFile(
    path: '/roms/Super Mario Bros. (W).nes',
    name: 'Super Mario Bros. (W).nes',
    type: FilesystemFileType.file,
  ),
);

final _time = DateTime(2026, 9, 16, 14, 5, 9);

const _fileName = 'Super Mario Bros. (W) 2026-09-16 14-05-09.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNesState nesState;
  late _MockRemoteNes nes;
  late _MockSettingsController settings;
  late _MockToaster toaster;
  late List<(String, Uint8List)> written;

  setUpAll(() {
    registerFallbackValue(Toast.info('fallback'));
  });

  setUp(() {
    nesState = _MockNesState();
    nes = _MockRemoteNes();
    settings = _MockSettingsController();
    toaster = _MockToaster();
    written = [];

    when(() => nesState.nes).thenReturn(nes);
    when(() => nes.romInfo).thenReturn(_romInfo);
    when(() => settings.screenshotMode).thenReturn(ScreenshotMode.raw);
    when(
      nes.requestThumbnail,
    ).thenAnswer((_) async => (pixels: _frame(), width: 4, height: 2));
  });

  ScreenshotController controller({
    ui.Image? captured,
    Future<String> Function(String, Uint8List)? writer,
  }) => ScreenshotController(
    nesState: nesState,
    settingsController: settings,
    toaster: toaster,
    displayCapture: _FakeDisplayCapture(captured),
    now: () => _time,
    writer:
        writer ??
        (name, png) async {
          written.add((name, png));

          return '~/Pictures/NESd/$name';
        },
  );

  List<String> toasts(ToastType type) =>
      verify(() => toaster.send(captureAny())).captured
          .whereType<Toast>()
          .where((t) => t.type == type)
          .map((t) => t.message)
          .toList();

  test('names the file after the ROM and the time', () {
    expect(screenshotFileName(_romInfo, _time), _fileName);
  });

  test('strips characters that are invalid in file names', () {
    const romInfo = RomInfo(
      file: FilesystemFile(
        path: 'game.zip:Sub/Dir\\Name: "Q?".nes',
        name: 'Sub/Dir\\Name: "Q?".nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(
      screenshotFileName(romInfo, _time),
      'Sub_Dir_Name_ _Q__ 2026-09-16 14-05-09.png',
    );
  });

  test('saves the raw frame as a PNG and toasts the location', () async {
    await controller().takeScreenshot();

    expect(written, hasLength(1));

    final (name, png) = written.single;

    expect(name, _fileName);

    final decoded = img.decodePng(png)!;

    expect(decoded.width, 4);
    expect(decoded.height, 2);
    expect(decoded.getPixel(1, 0).r, 1 * 16);
    expect(decoded.getPixel(3, 1).g, 7 * 16);

    expect(toasts(ToastType.info), [
      'Saved screenshot to ~/Pictures/NESd/$_fileName',
    ]);
  });

  test('saves the displayed frame when the setting asks for it', () async {
    when(() => settings.screenshotMode).thenReturn(ScreenshotMode.displayed);

    await controller(captured: await _image(6, 3)).takeScreenshot();

    final decoded = img.decodePng(written.single.$2)!;

    expect(decoded.width, 6);
    expect(decoded.height, 3);

    verifyNever(nes.requestThumbnail);
  });

  test(
    'falls back to the raw frame when the display cannot be captured',
    () async {
      when(() => settings.screenshotMode).thenReturn(ScreenshotMode.displayed);

      await controller().takeScreenshot();

      final decoded = img.decodePng(written.single.$2)!;

      expect(decoded.width, 4);
      expect(toasts(ToastType.info), hasLength(1));
    },
  );

  test('toasts an error when the worker does not answer', () async {
    when(nes.requestThumbnail).thenAnswer((_) async => null);

    await controller().takeScreenshot();

    expect(written, isEmpty);
    expect(toasts(ToastType.error), ['Could not capture the screen']);
  });

  test('toasts an error when writing fails', () async {
    await controller(
      writer: (_, _) async => throw const FileSystemException('read-only'),
    ).takeScreenshot();

    expect(toasts(ToastType.error), ['Could not save screenshot']);
  });

  test('does nothing without a running game', () async {
    when(() => nesState.nes).thenReturn(null);

    await controller().takeScreenshot();

    expect(written, isEmpty);
    verifyNever(() => toaster.send(any()));
  });
}

Uint8List _frame() {
  final pixels = Uint8List(4 * 2 * 4);

  for (var i = 0; i < 8; i++) {
    pixels[i * 4] = (i % 4) * 16;
    pixels[i * 4 + 1] = i * 16;
    pixels[i * 4 + 3] = 255;
  }

  return pixels;
}

Future<ui.Image> _image(int width, int height) {
  final recorder = ui.PictureRecorder();

  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff123456),
  );

  return recorder.endRecording().toImage(width, height);
}
