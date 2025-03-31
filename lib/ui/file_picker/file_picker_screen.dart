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
    final state = ref.watch(filePickerNotifierProvider);
    final controller = ref.watch(filePickerControllerProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.go(initialDirectory),
      );

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
      FilePickerData(path: final path, files: final files) => FilePicker(
        title: title,
        path: path,
        files: files,
        allowedExtensions: allowedExtensions,
        onChangeDirectory: onChangeDirectory,
      ),
    };
  }
}

class FilePicker extends StatelessWidget {
  const FilePicker({
    required this.title,
    required this.path,
    required this.files,
    required this.allowedExtensions,
    this.onChangeDirectory,
    super.key,
  });

  final String title;
  final String path;
  final List<FileSystemFile> files;
  final List<String> allowedExtensions;
  final void Function(Directory p1)? onChangeDirectory;

  @override
  Widget build(BuildContext context) {
    return NesdScaffold(
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
                DirectoryPickerButton(
                  path: path,
                  onChangeDirectory: onChangeDirectory,
                ),
                FileList(
                  path: path,
                  files: files,
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

class DirectoryPickerButton extends ConsumerWidget {
  const DirectoryPickerButton({
    required this.path,
    this.onChangeDirectory,
    super.key,
  });

  final String path;
  final void Function(Directory p1)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesystem = ref.watch(fileSystemProvider);
    final controller = ref.watch(filePickerControllerProvider);

    return InkWell(
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
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class FileList extends HookConsumerWidget {
  const FileList({
    required this.path,
    required this.files,
    required this.allowedExtensions,
    this.onChangeDirectory,
    super.key,
  });

  final String path;
  final List<FileSystemFile> files;
  final List<String> allowedExtensions;
  final void Function(Directory p1)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    final scrollController = useScrollController();
    final textEditingController = useTextEditingController();

    return Expanded(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            floating: true,
            leading: const Icon(Icons.search),
            title: FocusOnHover(
              child: TextField(
                controller: textEditingController,
                onChanged: (value) => controller.filter = value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Search',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SliverList.separated(
            itemBuilder: (context, index) {
              if (index == 0) {
                return ParentTile(
                  path: path,
                  onChangeDirectory: onChangeDirectory,
                );
              }

              final file = files[index - 1];

              return FileTile(
                enabled:
                    file.type == FileSystemFileType.directory ||
                    allowedExtensions.isEmpty ||
                    allowedExtensions.contains(
                      p.extension(file.path).toLowerCase(),
                    ),
                isDirectory: file.type == FileSystemFileType.directory,
                file: file,
                fileIsZip: p.extension(file.path) == '.zip',
                onChangeDirectory: onChangeDirectory,
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: files.length + 1,
          ),
        ],
      ),
    );
  }
}

class ParentTile extends ConsumerWidget {
  const ParentTile({required this.path, this.onChangeDirectory, super.key});

  final String path;
  final void Function(Directory p1)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    return FocusOnHover(
      child: ListTile(
        leading: Icon(Icons.drive_folder_upload_rounded, color: nesdRed[500]),
        title: const Text('Up a directory'),
        onTap: () {
          final parentDirectory = Directory(path).parent;

          controller.go(parentDirectory.path);

          onChangeDirectory?.call(parentDirectory);
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
  final FileSystemFile file;
  final bool fileIsZip;
  final void Function(Directory p1)? onChangeDirectory;

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
        title: Text(p.basename(file.path)),
        onTap: () async {
          if (isDirectory) {
            await controller.go(file.path);

            onChangeDirectory?.call(Directory(file.path));
          } else if (fileIsZip) {
            await controller.go(file.path);
          } else {
            await context.router.maybePop(file);
          }
        },
      ),
    );
  }
}
