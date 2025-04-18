import 'dart:async';

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
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
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
  final FilesystemFile initialDirectory;
  final FilePickerType type;
  final List<String> allowedExtensions;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(filePickerNotifierProvider, (_, next) {
      if (next is FilePickerData &&
          p.extension(next.directory.path) == '.zip' &&
          next.files.length == 1) {
        scheduleMicrotask(() {
          final file = next.files.first;

          if (file.type == FilesystemFileType.file) {
            context.router.maybePop(file);
          }
        });
      }
    });

    final controller = ref.watch(filePickerControllerProvider);

    useEffect(() {
      scheduleMicrotask(() => controller.go(initialDirectory));

      return null;
    }, [initialDirectory]);

    return FilePicker(
      title: title,
      allowedExtensions: allowedExtensions,
      onChangeDirectory: onChangeDirectory,
    );
  }
}

class FilePicker extends ConsumerWidget {
  const FilePicker({
    required this.title,
    required this.allowedExtensions,
    this.onChangeDirectory,
    super.key,
  });

  final String title;
  final List<String> allowedExtensions;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: FocusChild(
            autofocus: true,
            child: Column(
              children: [
                DirectoryPickerButton(onChangeDirectory: onChangeDirectory),
                Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FocusOnHover(
                        child: TextField(
                          controller: controller.textEditingController,
                          onChanged: (value) => controller.filter = value,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Filter',
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const FilePickerProgressIndicator(),
                FileList(
                  allowedExtensions: allowedExtensions,
                  onChangeDirectory: onChangeDirectory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilePickerProgressIndicator extends ConsumerWidget {
  const FilePickerProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filePickerNotifierProvider);

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child:
          state is FilePickerData && state.refreshing
              ? const LinearProgressIndicator()
              : null,
    );
  }
}

class DirectoryPickerButton extends ConsumerWidget {
  const DirectoryPickerButton({this.onChangeDirectory, super.key});

  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesystem = ref.watch(filesystemProvider);
    final controller = ref.watch(filePickerControllerProvider);
    final state = ref.watch(filePickerNotifierProvider);

    final currentDirectory = state is FilePickerData ? state.directory : null;

    return InkWell(
      onTap: () async {
        final path = currentDirectory?.path;

        if (path == null) {
          return;
        }

        final result = await filesystem.chooseDirectory(path);

        if (result != null) {
          controller.go(result);

          onChangeDirectory?.call(result);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            currentDirectory?.name ?? '',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
        ),
      ),
    );
  }
}

class FileList extends HookConsumerWidget {
  const FileList({
    required this.allowedExtensions,
    this.onChangeDirectory,
    super.key,
  });

  final List<String> allowedExtensions;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filePickerNotifierProvider);

    final scrollController = useScrollController();

    return Expanded(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          switch (state) {
            FilePickerLoading() => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            FilePickerError(message: final message) => SliverToBoxAdapter(
              child: Center(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontVariations: const [FontVariation.weight(700)],
                  ),
                ),
              ),
            ),
            FilePickerData(directory: final directory, files: final files) =>
              SliverList.separated(
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ParentTile(
                      directory: directory,
                      onChangeDirectory: onChangeDirectory,
                    );
                  }

                  final file = files[index - 1];

                  return FileTile(
                    enabled:
                        file.type == FilesystemFileType.directory ||
                        allowedExtensions.isEmpty ||
                        allowedExtensions.contains(
                          p.extension(file.path).toLowerCase(),
                        ),
                    isDirectory: file.type == FilesystemFileType.directory,
                    file: file,
                    fileIsZip: p.extension(file.path) == '.zip',
                    onChangeDirectory: onChangeDirectory,
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                itemCount: files.length + 1,
              ),
          },
        ],
      ),
    );
  }
}

class ParentTile extends ConsumerWidget {
  const ParentTile({
    required this.directory,
    this.onChangeDirectory,
    super.key,
  });

  final FilesystemFile directory;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);
    final filesystem = ref.watch(filesystemProvider);

    return FocusOnHover(
      child: ListTile(
        leading: Icon(Icons.drive_folder_upload_rounded, color: nesdRed[500]),
        title: const Text('Up a directory'),
        onTap: () async {
          final parent = await filesystem.parent(directory.path);

          if (parent == null) {
            return;
          }

          controller.go(parent);

          onChangeDirectory?.call(parent);
        },
      ),
    );
  }
}

class FileTile extends ConsumerWidget {
  const FileTile({
    required this.isDirectory,
    required this.enabled,
    required this.file,
    required this.fileIsZip,
    this.onChangeDirectory,
    super.key,
  });

  final bool isDirectory;
  final bool enabled;
  final FilesystemFile file;
  final bool fileIsZip;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

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
        title: Text(p.basename(file.name)),
        onTap: () async {
          if (isDirectory) {
            controller.go(file);

            onChangeDirectory?.call(file);
          } else if (fileIsZip) {
            controller.go(file);
          } else {
            await context.router.maybePop(file);
          }
        },
      ),
    );
  }
}
