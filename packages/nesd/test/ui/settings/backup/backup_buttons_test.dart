import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/backup/settings_backup.dart';
import 'package:nesd/ui/settings/backup/settings_backup_actions.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../../../helpers/fake_platform_file.dart';
import '../settings_robot.dart';

class _FakeBackupActions implements SettingsBackupActions {
  _FakeBackupActions({this.picked, this.saveResult});

  final PlatformFile? picked;
  final Uri? saveResult;

  String? exported;
  String? exportedName;

  @override
  Future<Uri?> exportBackup(String contents, {required String fileName}) async {
    exported = contents;
    exportedName = fileName;

    return saveResult;
  }

  @override
  Future<PlatformFile?> pickBackup() async => picked;
}

FakePlatformFile _file(String contents) => FakePlatformFile(
  name: 'backup.json',
  path: '',
  bytes: Uint8List.fromList(utf8.encode(contents)),
);

const _rom = RomInfo(
  file: FilesystemFile(
    path: '/roms/game.nes',
    name: 'game.nes',
    type: FilesystemFileType.file,
  ),
  hash: 'abc',
);

void main() {
  late SettingsScreenRobot robot;

  Future<_FakeBackupActions> pump(
    WidgetTester tester, {
    PlatformFile? picked,
    Uri? saveResult,
  }) async {
    final actions = _FakeBackupActions(picked: picked, saveResult: saveResult);

    robot = SettingsScreenRobot(tester);

    await robot.pumpSettingsScreen(
      overrides: [settingsBackupActionsProvider.overrideWithValue(actions)],
    );
    robot.container.listen(toasterProvider, (_, _) {});
    await robot.openCategory(SettingsCategory.advanced);

    return actions;
  }

  Future<void> tapTile(WidgetTester tester, String title) async {
    final finder = find.text(title);

    await tester.ensureVisible(finder);
    await robot.go(finder);
  }

  SettingsController controller() =>
      robot.container.read(settingsControllerProvider.notifier);

  Toast toast() => robot.container.read(toastStateProvider).single;

  testWidgets('export saves the current settings', (tester) async {
    final actions = await pump(tester, saveResult: Uri.file('/tmp/x.json'));

    controller().volume = 0.3;

    await tapTile(tester, 'Export settings…');

    expect(actions.exportedName, startsWith('nesd-settings-'));
    expect(decodeSettingsBackup(actions.exported!)['volume'], 0.3);
    expect(toast().message, 'Settings exported');
  });

  testWidgets('a cancelled export shows nothing', (tester) async {
    await pump(tester);

    await tapTile(tester, 'Export settings…');

    expect(robot.container.read(toastStateProvider), isEmpty);
  });

  testWidgets('import applies the file after confirmation', (tester) async {
    final file = encodeSettingsBackup(Settings(volume: 0.4), now: DateTime(0));

    await pump(tester, picked: _file(file));

    await tapTile(tester, 'Import settings…');

    expect(find.text('Import settings?'), findsOneWidget);

    await robot.go(find.text('Import'));

    expect(controller().state.volume, 0.4);
    expect(toast().message, 'Settings imported');
  });

  testWidgets('cancelling the confirmation imports nothing', (tester) async {
    final file = encodeSettingsBackup(Settings(volume: 0.4), now: DateTime(0));

    await pump(tester, picked: _file(file));

    await tapTile(tester, 'Import settings…');
    await robot.go(find.text('Cancel'));

    expect(controller().state.volume, 1.0);
    expect(robot.container.read(toastStateProvider), isEmpty);
  });

  testWidgets('skipped entries are reported', (tester) async {
    await pump(
      tester,
      picked: _file(
        jsonEncode({
          'version': settingsBackupVersion,
          'settings': {'volume': 'loud', 'lowPassFilter': true},
        }),
      ),
    );

    await tapTile(tester, 'Import settings…');
    await robot.go(find.text('Import'));

    expect(controller().state.lowPassFilter, isTrue);
    expect(toast().type, ToastType.warning);
    expect(
      toast().message,
      'Settings imported; 1 entry could not be read and was skipped',
    );
  });

  testWidgets('a file that is not a backup is rejected without asking', (
    tester,
  ) async {
    await pump(tester, picked: _file('{"hello": "world"}'));

    await tapTile(tester, 'Import settings…');

    expect(find.text('Import settings?'), findsNothing);
    expect(toast().type, ToastType.error);
    expect(
      toast().message,
      'Could not import backup.json: not a NESd settings file',
    );
  });

  testWidgets('reset restores the defaults after confirmation and keeps '
      'recent ROMs', (tester) async {
    await pump(tester);

    controller()
      ..volume = 0.3
      ..addRecentRom(_rom);

    await tapTile(tester, 'Reset to defaults');

    expect(find.text('Reset settings?'), findsOneWidget);

    await robot.go(find.text('Reset'));

    expect(controller().state.volume, 1.0);
    expect(controller().state.recentRoms, [_rom]);
    expect(toast().message, 'Settings reset to defaults');
  });
}
