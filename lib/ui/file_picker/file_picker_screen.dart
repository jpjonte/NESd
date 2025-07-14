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
    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
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
                const SearchBox(),
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

class SearchBox extends HookConsumerWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    final focused = useState(false);

    final colorScheme = Theme.of(context).colorScheme;

    return FocusOnHover(
      onFocusChange: (hasFocus) => focused.value = hasFocus,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: focused.value ? colorScheme.primary : colorScheme.surface,
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: focused.value ? colorScheme.onPrimary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                cursorColor: focused.value ? colorScheme.onPrimary : null,
                style: TextStyle(
                  color: focused.value ? colorScheme.onPrimary : null,
                ),
                controller: controller.textEditingController,
                onChanged: (value) => controller.filter = value,
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    color: focused.value ? Colors.grey[300] : null,
                  ),
                  border: const OutlineInputBorder(),
                  hintText: 'Filter',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
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

    final loading = state is FilePickerData && state.refreshing;

    return Container(
      height: loading ? 4 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: loading ? const LinearProgressIndicator() : null,
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

    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: InkWell(
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
                fontSize: theme.textTheme.bodyLarge?.fontSize,
                fontVariations: const [FontVariation.weight(700)],
              ),
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
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              Icons.drive_folder_upload_rounded,
              color: focused ? colorScheme.onPrimary : colorScheme.primary,
            ),
            title: Text(
              'Up a directory',
              style: TextStyle(color: focused ? colorScheme.onPrimary : null),
            ),
            onTap: () async {
              final parent = await filesystem.parent(directory.path);

              if (parent == null) {
                return;
              }

              controller.go(parent);

              onChangeDirectory?.call(parent);
            },
          );
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
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            leading: Icon(
              isDirectory
                  ? Icons.folder
                  : enabled
                  ? Icons.videogame_asset
                  : null,
              color: focused ? colorScheme.onPrimary : colorScheme.primary,
            ),
            enabled: enabled,
            title: Text(
              p.basename(file.name),
              style: TextStyle(color: focused ? colorScheme.onPrimary : null),
            ),
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
          );
        },
      ),
    );
  }
}
