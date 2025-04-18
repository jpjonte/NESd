import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base_robot.dart';
import 'emulator/emulator_robot.dart';
import 'emulator/main_menu/main_menu_robot.dart';
import 'file_picker/file_picker_screen_robot.dart';
import 'menu/menu_screen_robot.dart';
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
      filePickerScreen = FilePickerScreenRobot(tester) {
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

  ProviderContainer get container =>
      (tester.widget(find.byType(UncontrolledProviderScope))
              as UncontrolledProviderScope)
          .container;

  SettingsController get settings =>
      container.read(settingsControllerProvider.notifier);

  void initSettings(Map<String, Object> values) =>
      SharedPreferences.setMockInitialValues({'settings': jsonEncode(values)});

  Future<void> pumpApp() async {
    final mockAudioStream = MockAudioStream();
    final fileSystem =
        MockFileSystem()
          ..addFile(
            '/test/roms/nestest.nes',
            File('roms/test/nestest/nestest.nes').readAsBytesSync(),
          )
          ..addFile('/test/roms/z_fake.nes', Uint8List(0));

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

    tester.view.physicalSize =
        const Size(1920, 1080) * tester.view.devicePixelRatio;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioOutputProvider.overrideWithValue(
            AudioOutput(audioStream: mockAudioStream),
          ),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          packageInfoProvider.overrideWithValue(packageInfo),
          filesystemProvider.overrideWithValue(fileSystem),
          applicationSupportPathProvider.overrideWithValue('/tmp/nesd'),
        ],
        child: const NesdApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(String filename) async {
    await tester.runAsync(() async {
      final image = await captureImage(
        tester.element(find.byType(ProviderScope)),
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
