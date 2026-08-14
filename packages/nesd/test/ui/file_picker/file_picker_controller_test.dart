import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';

class _MockFilesystem extends Mock implements Filesystem {}

class _MockSettingsController extends Mock implements SettingsController {}

const _directory = FilesystemFile(
  path: '/roms',
  name: '/roms',
  type: FilesystemFileType.directory,
);

FilesystemFile _file(String name) =>
    FilesystemFile(path: name, name: name, type: FilesystemFileType.file);

FilesystemFile _subDirectory(String name) =>
    FilesystemFile(path: name, name: name, type: FilesystemFileType.directory);

void main() {
  late _MockFilesystem filesystem;
  late ProviderContainer container;
  late FilePickerController controller;

  setUp(() {
    filesystem = _MockFilesystem();
    container = ProviderContainer();

    addTearDown(container.dispose);

    final subscription = container.listen(filePickerStateProvider, (_, _) {});

    addTearDown(subscription.close);

    controller = FilePickerController(
      filesystem: filesystem,
      notifier: container.read(filePickerStateProvider.notifier),
      settingsController: _MockSettingsController(),
    );

    when(() => filesystem.isDirectory('/roms')).thenAnswer((_) async => true);
  });

  List<String> currentFileNames() {
    final state = container.read(filePickerStateProvider);

    expect(state, isA<FilePickerData>());

    return [for (final file in (state as FilePickerData).files) file.name];
  }

  Future<void> applyFilter(String filter) async {
    controller.filter = filter;

    await pumpEventQueue();
  }

  test('keeps directories first when no filter is set', () async {
    when(
      () => filesystem.list('/roms'),
    ).thenAnswer((_) async => [_file('Zelda.nes'), _subDirectory('homebrew')]);

    await controller.go(_directory);

    expect(currentFileNames(), ['homebrew', 'Zelda.nes']);
  });

  test('includes files that fuzzy-match the filter', () async {
    when(() => filesystem.list('/roms')).thenAnswer(
      (_) async => [_file('Super Mario Bros.nes'), _file('Tetris.nes')],
    );

    await controller.go(_directory);
    await applyFilter('supebro');

    expect(currentFileNames(), ['Super Mario Bros.nes']);
  });

  test('ranks better matches first when a filter is set', () async {
    when(() => filesystem.list('/roms')).thenAnswer(
      (_) async => [
        _file('Mah Jong Trio.nes'),
        _file('Mario Bros.nes'),
        _file('Tetris.nes'),
      ],
    );

    await controller.go(_directory);
    await applyFilter('mario');

    expect(currentFileNames(), ['Mario Bros.nes', 'Mah Jong Trio.nes']);
  });

  test('restores the full listing when the filter is cleared', () async {
    when(() => filesystem.list('/roms')).thenAnswer(
      (_) async => [
        _file('Tetris.nes'),
        _file('Mario Bros.nes'),
        _subDirectory('homebrew'),
      ],
    );

    await controller.go(_directory);
    await applyFilter('mario');

    expect(currentFileNames(), ['Mario Bros.nes']);

    await applyFilter('');

    expect(currentFileNames(), ['homebrew', 'Mario Bros.nes', 'Tetris.nes']);
  });

  test(
    'matches zip entries on their displayed name, not the zip path',
    () async {
      when(() => filesystem.list('/roms')).thenAnswer(
        (_) async => [
          const FilesystemFile(
            path: '/roms/pack.zip:Mario.nes',
            name: 'Mario.nes',
            type: FilesystemFileType.file,
          ),
          const FilesystemFile(
            path: '/roms/pack.zip:Tetris.nes',
            name: 'Tetris.nes',
            type: FilesystemFileType.file,
          ),
        ],
      );

      await controller.go(_directory);
      await applyFilter('pack');

      expect(currentFileNames(), isEmpty);
    },
  );

  test('puts directories first for equally good matches', () async {
    when(
      () => filesystem.list('/roms'),
    ).thenAnswer((_) async => [_file('Mario.nes'), _subDirectory('Mario')]);

    await controller.go(_directory);
    await applyFilter('mario');

    expect(currentFileNames(), ['Mario', 'Mario.nes']);
  });
}
