import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../robot.dart';

class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.path);

  final String path;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    Object? androidSafOptions,
  }) async {
    return FilePickerResult([
      PlatformFile(path: path, name: 'nestest.nes', size: 0),
    ]);
  }
}

void main() {
  testWidgets('opening a ROM via the native file dialog switches to the '
      'emulator route', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/native.nes': File(
          '../../roms/test/nestest/nestest.nes',
        ).readAsBytesSync(),
      },
    );

    FilePickerPlatform.instance = FakeFilePickerPlatform(
      '/test/roms/native.nes',
    );

    addTearDown(() => FilePickerPlatform.instance = MethodChannelFilePicker());

    await r.container.read(nesControllerProvider).selectRom();
    await r.waitUntil(() => r.container.read(nesStateProvider) != null);

    await r.waitUntil(
      () => r.container.read(routerObserverProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
