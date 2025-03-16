import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:path/path.dart' as p;

enum FilePickerType { file, directory, any }

@RoutePage()
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

    final state = ref.watch(filePickerNotifierProvider);
    final controller = ref.watch(filePickerControllerProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.go(initialDirectory);
      });

      return null;
    }, [initialDirectory]);

    if (state is FilePickerData &&
        p.extension(state.path) == '.zip' &&
        state.files.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final file = state.files.first;

        if (file.type == FileSystemFileType.file) {
          context.router.maybePop(file);
        }
      });
    }

    return switch (state) {
      FilePickerLoading() => const Center(child: CircularProgressIndicator()),
      FilePickerError(message: final message) => Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      FilePickerData(path: final path, files: final files) => NesdScaffold(
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
                      final result = await filesystem.chooseDirectory(path);

                      if (result != null) {
                        final newDirectory = Directory(result);

                        controller.go(result);

                        onChangeDirectory?.call(newDirectory);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          path,
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
                                final parentDirectory = Directory(path).parent;

                                controller.go(parentDirectory.path);

                                onChangeDirectory?.call(parentDirectory);
                              },
                            ),
                          );
                        }

                        final file = files[index - 1];

                        final isDirectory =
                            file.type == FileSystemFileType.directory;

                        final fileIsZip = p.extension(file.path) == '.zip';

                        final enabled =
                            isDirectory ||
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
                            onTap: () async {
                              if (isDirectory) {
                                controller.go(file.path);

                                onChangeDirectory?.call(Directory(file.path));
                              } else if (fileIsZip) {
                                controller.go(file.path);
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
      ),
    };
  }
}
