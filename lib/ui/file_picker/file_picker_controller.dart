import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:nesd/ui/file_picker/file_system/zip_file_system.dart';
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
    filesystem: ref.watch(fileSystemProvider),
  );
}

class FilePickerController {
  FilePickerController({required this.filesystem, required this.notifier});

  final FileSystem filesystem;
  final FilePickerNotifier notifier;

  String? _filter;

  // ignore: avoid_setters_without_getters
  set filter(String? value) {
    _filter = value;

    if (notifier.current case final FilePickerData data) {
      go(data.path);
    }
  }

  Future<void> go(String path) async {
    notifier.update(FilePickerLoading());

    if (p.extension(path) == '.zip') {
      _listFilesFromZip(path);

      return;
    }

    if (await filesystem.isDirectory(path)) {
      _listFilesFromDirectory(path);

      return;
    }

    notifier.update(
      FilePickerError('$path is not a valid directory or zip file'),
    );
  }

  Future<void> _listFilesFromZip(String path) async {
    final zipData = await filesystem.read(path);
    final zipFileSystem = ZipFileSystem(path: path, zipData: zipData);

    _listFilesFromFileSystem(zipFileSystem, path);
  }

  Future<void> _listFilesFromDirectory(String path) async {
    _listFilesFromFileSystem(filesystem, path);
  }

  Future<void> _listFilesFromFileSystem(
    FileSystem filesystem,
    String path,
  ) async {
    final (resultPath, allFiles) = await filesystem.list(path);

    var returnPath = path;

    if (resultPath != path) {
      returnPath = resultPath;
    }

    final children =
        allFiles.where((file) => !p.basename(file.path).startsWith('.')).where((
            file,
          ) {
            if (_filter case final filter?) {
              final filename = p.basename(file.path);

              return filename.toLowerCase().contains(filter.toLowerCase());
            }

            return true;
          }).toList()
          ..sort((a, b) {
            final aType = a.type;
            final bType = b.type;

            if (aType == FileSystemFileType.directory &&
                bType != FileSystemFileType.directory) {
              return -1;
            } else if (aType != FileSystemFileType.directory &&
                bType == FileSystemFileType.directory) {
              return 1;
            }

            return a.path.compareTo(b.path);
          });

    notifier.update(FilePickerData(path: returnPath, files: children));
  }
}
