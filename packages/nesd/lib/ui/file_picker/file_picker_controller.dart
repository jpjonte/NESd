import 'package:flutter/widgets.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:nesd/ui/file_picker/fuzzy_matcher.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_picker_controller.g.dart';

@riverpod
class FilePickerStateNotifier extends _$FilePickerStateNotifier {
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
    notifier: ref.watch(filePickerStateProvider.notifier),
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
  final FilePickerStateNotifier notifier;
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

  String? _entryPath;

  /// true while the current directory is strictly below the directory the
  /// picker was opened at
  bool get insideEntryDirectory {
    final entryPath = _entryPath;

    if (entryPath == null) {
      return false;
    }

    if (notifier.current case final FilePickerData data) {
      return p.isWithin(entryPath, data.directory.path);
    }

    return false;
  }

  String? _pendingFocusPath;

  String? takePendingFocusPath() {
    final path = _pendingFocusPath;

    _pendingFocusPath = null;

    return path;
  }

  Future<FilesystemFile?> goUp() async {
    final state = notifier.current;

    if (state is! FilePickerData) {
      return null;
    }

    final directory = state.directory;

    final FilesystemFile? parent;

    try {
      parent = await filesystem.parent(directory.path);
    } on NesdException catch (e) {
      log.storage.warning(
        'Could not resolve the parent directory',
        context: {'path': directory.path},
        error: e,
      );

      return null;
    }

    if (parent == null || parent.path == directory.path) {
      return null;
    }

    await go(
      parent,
      focusPath: directory.path,
      isEntryPoint: _entryPath != null && !insideEntryDirectory,
    );

    return parent;
  }

  Future<void> go(
    FilesystemFile directory, {
    String? focusPath,
    bool isEntryPoint = false,
  }) async {
    _pendingFocusPath = focusPath;

    if (isEntryPoint) {
      _entryPath = directory.path;
    }

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

      final matches =
          allFiles
              .where((file) => !p.basename(file.path).startsWith('.'))
              .map((file) {
                final score = fuzzyScore(_filter ?? '', p.basename(file.name));

                return score == null ? null : (file: file, score: score);
              })
              .nonNulls
              .toList()
            ..sort((a, b) {
              final byScore = b.score.compareTo(a.score);

              if (byScore != 0) {
                return byScore;
              }

              final aDirectory = a.file.type == FilesystemFileType.directory;
              final bDirectory = b.file.type == FilesystemFileType.directory;

              if (aDirectory != bDirectory) {
                return aDirectory ? -1 : 1;
              }

              return a.file.path.toLowerCase().compareTo(
                b.file.path.toLowerCase(),
              );
            });

      final children = [for (final match in matches) match.file];

      notifier.update(FilePickerData(directory: directory, files: children));
    } on NesdException catch (e) {
      log.storage.warning(
        'Could not list archive contents',
        context: {'path': directory.path},
        error: e,
      );

      notifier.update(FilePickerError(e.message));

      if (directory.path == settingsController.lastRomPath?.path) {
        settingsController.lastRomPath = null;
      }
    }
  }

  Future<void> _update(FilesystemFile directory) async {
    try {
      if (isZipFile(directory.path)) {
        await _listFilesFromZip(directory);

        return;
      }

      if (await filesystem.isDirectory(directory.path)) {
        await _listFilesFromDirectory(directory);

        return;
      }
    } on NesdException catch (e) {
      log.storage.warning(
        'Could not open path in the file picker',
        context: {'path': directory.path},
        error: e,
      );

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
