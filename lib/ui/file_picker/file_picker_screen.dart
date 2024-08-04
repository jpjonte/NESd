import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;

enum FilePickerType {
  file,
  directory,
  any,
}

@RoutePage<String?>()
class FilePickerScreen extends HookConsumerWidget {
  const FilePickerScreen({
    required this.title,
    required this.initialDirectory,
    required this.type,
    this.allowedExtensions = const [],
    this.onChangeDirectory,
    super.key,
  });

  final String title;
  final String initialDirectory;
  final FilePickerType type;
  final List<String> allowedExtensions;
  final void Function(Directory)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesystem = ref.watch(fileSystemProvider);
    final settingsController = ref.watch(settingsControllerProvider.notifier);

    final directory = useState(Directory(initialDirectory));

    final future = useMemoized(
      () => _getFiles(filesystem, directory, settingsController),
      [directory.value],
    );

    final filesValue = useFuture(future);

    if (filesValue.hasError) {
      return Center(
        child: Text(
          filesValue.error.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (!filesValue.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final files = filesValue.data!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: FocusChild(
            autofocus: true,
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final result = await filesystem.chooseDirectory(
                      directory.value.path,
                    );

                    if (result != null) {
                      final newDirectory = Directory(result);

                      directory.value = newDirectory;
                      onChangeDirectory?.call(newDirectory);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        directory.value.path,
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.bodyLarge?.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return FocusOnHover(
                          child: ListTile(
                            leading: Icon(
                              Icons.drive_folder_upload_rounded,
                              color: nesdRed[500],
                            ),
                            title: const Text('Up a directory'),
                            onTap: () {
                              final parentDirectory = directory.value.parent;

                              directory.value = parentDirectory;

                              onChangeDirectory?.call(parentDirectory);
                            },
                          ),
                        );
                      }

                      final file = files[index - 1];

                      final isDirectory =
                          file.type == FileSystemFileType.directory;

                      final enabled = isDirectory ||
                          allowedExtensions.isEmpty ||
                          allowedExtensions.contains(p.extension(file.path));

                      return FocusOnHover(
                        child: ListTile(
                          leading: Icon(
                            isDirectory
                                ? Icons.folder
                                : enabled
                                    ? Icons.videogame_asset
                                    : null,
                            color: nesdRed[500],
                          ),
                          enabled: enabled,
                          title: Text(p.basename(file.path)),
                          onTap: () {
                            // TODO directory selection mode
                            if (isDirectory) {
                              directory.value = Directory(file.path);
                              onChangeDirectory?.call(Directory(file.path));
                            } else {
                              context.router.maybePop(file);
                            }
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: files.length + 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<FileSystemFile>> _getFiles(
    FileSystem filesystem,
    ValueNotifier<Directory> directory,
    SettingsController settingsController,
  ) async {
    final (resultDirectory, allFiles) = await filesystem.list(
      directory.value.path,
    );

    if (resultDirectory != directory.value.path) {
      directory.value = Directory(resultDirectory);
    }

    final children = allFiles.where((file) {
      if (p.basename(file.path).startsWith('.')) {
        return false;
      }

      if (type == FilePickerType.directory) {
        return file is Directory;
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

    return children;
  }
}
