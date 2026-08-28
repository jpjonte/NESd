import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base_robot.dart';
import 'emulator/emulator_robot.dart';
import 'emulator/main_menu/main_menu_robot.dart';
import 'file_picker/file_picker_screen_robot.dart';
import 'menu/menu_screen_robot.dart';
import 'menu/tools_screen_robot.dart';
import 'mocks.dart';
import 'save_states/save_states_robot.dart';
import 'settings/settings_robot.dart';

class Robot extends BaseRobot {
  Robot(super.tester)
    : mainMenu = MainMenuRobot(tester),
      settingsScreen = SettingsScreenRobot(tester),
      emulator = EmulatorRobot(tester),
      menuScreen = MenuScreenRobot(tester),
      saveStates = SaveStatesRobot(tester),
      filePickerScreen = FilePickerScreenRobot(tester),
      tools = ToolsScreenRobot(tester) {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;

    initSettings({});
  }

  final MainMenuRobot mainMenu;
  final SettingsScreenRobot settingsScreen;
  final EmulatorRobot emulator;
  final MenuScreenRobot menuScreen;
  final SaveStatesRobot saveStates;
  final FilePickerScreenRobot filePickerScreen;
  final ToolsScreenRobot tools;

  final List<FakeNesIsolateHandle> isolateHandles = [];

  final MockFileSystem fileSystem = MockFileSystem();

  ProviderContainer get container =>
      (tester.widget(find.byType(UncontrolledProviderScope))
              as UncontrolledProviderScope)
          .container;

  SettingsController get settings =>
      container.read(settingsControllerProvider.notifier);

  void initSettings(Map<String, Object> values) =>
      SharedPreferences.setMockInitialValues({'settings': jsonEncode(values)});

  /// Emits a press of the button bound to [action], as the gamepad input
  /// handler would.
  void sendInputAction(InputAction action) {
    container
        .read(actionStreamProvider)
        .add(
          InputActionEvent(
            action: action,
            value: 1,
            bindingType: BindingType.hold,
          ),
        );
  }

  Future<void> pumpApp({
    Map<String, Uint8List> extraFiles = const {},
    Size logicalSize = const Size(1920, 1080),
    double? devicePixelRatio,
    List<Override> overrides = const [],
    bool settle = true,
  }) async {
    fileSystem
      ..addFile(
        '/test/roms/nestest.nes',
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      )
      ..addFile('/test/roms/z_fake.nes', Uint8List(0));

    for (final entry in extraFiles.entries) {
      fileSystem.addFile(entry.key, entry.value);
    }

    final sharedPreferences = await SharedPreferences.getInstance();

    final packageInfo = PackageInfo(
      appName: 'NESd Test',
      packageName: 'dev.jpj.nesd.test',
      version: '0.0.0',
      buildNumber: '1337',
    );

    await _loadFont('Inter', ['assets/fonts/Inter-Regular.ttf']);
    await _loadFont('Ubuntu Mono', [
      'assets/fonts/UbuntuMono-Regular.ttf',
      'assets/fonts/UbuntuMono-Italic.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);

    final ratio = devicePixelRatio ?? tester.view.devicePixelRatio;

    tester.view
      ..devicePixelRatio = ratio
      ..physicalSize = logicalSize * ratio;

    final tempDir = _createTempDir();

    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nesIsolateSpawnerProvider.overrideWithValue(() async {
            final handle = FakeNesIsolateHandle();

            isolateHandles.add(handle);

            return handle;
          }),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          packageInfoProvider.overrideWithValue(packageInfo),
          filesystemProvider.overrideWithValue(fileSystem),
          applicationSupportPathProvider.overrideWithValue(tempDir.path),
          storageFilesystemProvider.overrideWithValue(
            NativeStorageFilesystem(),
          ),
          ...overrides,
        ],
        child: const RepaintBoundary(child: NesdApp()),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await fixAsync();
    }

    // RomManager's directory setup and migration run real IO across
    // several awaits. Drain them here so storage-touching actions later
    // settle within a single fixAsync round.
    var initialized = false;

    unawaited(
      container
          .read(romManagerProvider)
          .initialized
          .whenComplete(() => initialized = true),
    );

    await waitUntil(() => initialized);
  }

  Directory _createTempDir() {
    final random = Random().nextInt(1 << 32).toRadixString(36);
    final dir = Directory(path.join(Directory.systemTemp.path, 'nesd_$random'))
      ..createSync();

    return dir;
  }

  Future<void> screenshot(String filename, {double pixelRatio = 1.0}) async {
    await tester.runAsync(() async {
      final element = tester.element(find.byType(ProviderScope));

      var renderObject = element.renderObject!;

      while (!renderObject.isRepaintBoundary) {
        renderObject = renderObject.parent!;
      }

      final layer = renderObject.debugLayer! as OffsetLayer;

      final image = await layer.toImage(
        renderObject.paintBounds,
        pixelRatio: pixelRatio,
      );

      final bytes = await image.toByteData(format: ImageByteFormat.png);

      if (bytes != null) {
        File(filename).writeAsBytesSync(bytes.buffer.asUint8List());
      }
    });
  }

  Future<void> _loadFont(String family, List<String> fontFiles) async {
    final fontLoader = FontLoader(family);

    for (final fontFile in fontFiles) {
      final fontData = rootBundle.load(fontFile);

      fontLoader.addFont(fontData);
    }

    await fontLoader.load();
  }
}
