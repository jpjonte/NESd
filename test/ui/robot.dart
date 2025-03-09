import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base_robot.dart';
import 'emulator/main_menu_robot.dart';
import 'mocks.dart';

class Robot extends BaseRobot {
  Robot(super.tester) : mainMenu = MainMenuRobot(tester);

  final MainMenuRobot mainMenu;

  Future<void> pumpApp() async {
    SharedPreferences.setMockInitialValues({});

    final mockAudioStream = MockAudioStream();
    final fileSystem = MockFileSystem();

    final sharedPreferences = await SharedPreferences.getInstance();

    final packageInfo = PackageInfo(
      appName: 'NESd Test',
      packageName: 'dev.jpj.nesd.test',
      version: '0.0.0',
      buildNumber: '1337',
    );

    when(
      () => mockAudioStream.init(
        bufferMilliSec: any(named: 'bufferMilliSec'),
        waitingBufferMilliSec: any(named: 'waitingBufferMilliSec'),
        channels: any(named: 'channels'),
        sampleRate: any(named: 'sampleRate'),
      ),
    ).thenReturn(0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioOutputProvider.overrideWithValue(
            AudioOutput(audioStream: mockAudioStream),
          ),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          packageInfoProvider.overrideWithValue(packageInfo),
          fileSystemProvider.overrideWithValue(fileSystem),
          applicationSupportPathProvider.overrideWithValue('/tmp/nesd'),
        ],
        child: const NesdApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goBack() async {
    await go(find.byType(BackButton));
  }
}
