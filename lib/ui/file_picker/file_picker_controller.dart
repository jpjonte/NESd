import 'package:flutter/widgets.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_picker_controller.g.dart';

@riverpod
class FilePickerNotifier extends _$FilePickerNotifier {
  @override
  FilePickerState build() {
    return FilePickerLoading();
  }

  // can't use a setter to change the state from outside
  // ignore: use_setters_to_change_properties
  void update(FilePickerState state) {
    this.state = state;
  }

  FilePickerState get current => state;
}

@riverpod
FilePickerController filePickerController(Ref ref) {
  return FilePickerController(
    notifier: ref.watch(filePickerNotifierProvider.notifier),
    filesystem: ref.watch(filesystemProvider),
    settingsController: ref.watch(settingsControllerProvider.notifier),
  );
}

class FilePickerController {
  FilePickerController({
    required this.filesystem,
    required this.notifier,
    required this.settingsController,
  });

  final Filesystem filesystem;
  final FilePickerNotifier notifier;
  final SettingsController settingsController;

  final TextEditingController textEditingController = TextEditingController();

  String? _filter;

  // ignore: avoid_setters_without_getters
  set filter(String? value) {
    _filter = value;

    if (notifier.current case final FilePickerData data) {
      _update(data.directory);
    }
  }

  Future<void> go(FilesystemFile directory) async {
    final state = notifier.current;

    if (state is FilePickerData) {
      if (directory.path != state.directory.path) {
        _filter = null;
      }

      notifier.update(state.copyWith(refreshing: true));
    } else {
      notifier.update(FilePickerLoading());
    }

    textEditingController.clear();

    await _update(directory);
  }

  Future<void> _listFilesFromDirectory(FilesystemFile directory) async {
    _listFilesFromFileSystem(filesystem, directory);
  }

  Future<void> _listFilesFromZip(FilesystemFile directory) async {
    final zipData = await filesystem.read(directory.path);
    final zipFileSystem = ZipFilesystem(path: directory.path, zipData: zipData);

    _listFilesFromFileSystem(zipFileSystem, directory);
  }

  Future<void> _listFilesFromFileSystem(
    Filesystem filesystem,
    FilesystemFile directory,
  ) async {
    try {
      final allFiles = await filesystem.list(directory.path);

      final children =
          allFiles
              .where((file) => !p.basename(file.path).startsWith('.'))
              .where((file) {
                if (_filter case final filter?) {
                  final filename = p.basename(file.path);

                  return filename.toLowerCase().contains(filter.toLowerCase());
                }

                return true;
              })
              .toList()
            ..sort((a, b) {
              final aType = a.type;
              final bType = b.type;

              if (aType == FilesystemFileType.directory &&
                  bType != FilesystemFileType.directory) {
                return -1;
              } else if (aType != FilesystemFileType.directory &&
                  bType == FilesystemFileType.directory) {
                return 1;
              }

              return a.path.compareTo(b.path);
            });

      notifier.update(FilePickerData(directory: directory, files: children));
    } on NesdException catch (e) {
      notifier.update(FilePickerError(e.message));

      if (directory.path == settingsController.lastRomPath?.path) {
        settingsController.lastRomPath = null;
      }
    }
  }

  Future<void> _update(FilesystemFile directory) async {
    try {
      if (p.extension(directory.path) == '.zip') {
        await _listFilesFromZip(directory);

        return;
      }

      if (await filesystem.isDirectory(directory.path)) {
        await _listFilesFromDirectory(directory);

        return;
      }
    } on NesdException catch (e) {
      notifier.update(FilePickerError(e.message));

      if (directory.path == settingsController.lastRomPath?.path) {
        settingsController.lastRomPath = null;
      }

      return;
    }

    notifier.update(
      FilePickerError('${directory.path} is not a valid directory or zip file'),
    );
  }
}
