import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/file_picker/file_list.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

enum FilePickerType { file, directory, any }

@RoutePage()
class FilePickerScreen extends HookConsumerWidget {
  const FilePickerScreen({
    required this.title,
    required this.initialDirectory,
    required this.type,
    this.allowedExtensions = const [],
    this.onChangeDirectory,
    this.onSelect,
    super.key,
  });

  final String title;
  final FilesystemFile initialDirectory;
  final FilePickerType type;
  final List<String> allowedExtensions;
  final void Function(FilesystemFile)? onChangeDirectory;

  final Future<bool> Function(FilesystemFile)? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);

    Future<void> select(FilesystemFile file) async {
      final consume = onSelect;

      if (consume == null) {
        await context.router.maybePop(file);

        return;
      }

      if (busy.value) {
        return;
      }

      busy.value = true;

      try {
        await consume(file);
      } finally {
        if (context.mounted) {
          busy.value = false;
        }
      }
    }

    ref.listen(filePickerStateProvider, (_, next) {
      if (next is FilePickerData &&
          isArchiveFile(next.directory.path) &&
          next.files.length == 1) {
        scheduleMicrotask(() {
          final file = next.files.first;

          if (file.type == FilesystemFileType.file) {
            unawaited(select(file));
          }
        });
      }
    });

    final controller = ref.watch(filePickerControllerProvider);

    useEffect(() {
      scheduleMicrotask(
        () => controller.go(initialDirectory, isEntryPoint: true),
      );

      return null;
    }, [initialDirectory]);

    return FilePicker(
      title: title,
      allowedExtensions: allowedExtensions,
      onChangeDirectory: onChangeDirectory,
      onSelectFile: select,
      busy: busy.value,
    );
  }
}

class FilePicker extends ConsumerWidget {
  const FilePicker({
    required this.title,
    required this.allowedExtensions,
    required this.onSelectFile,
    required this.busy,
    this.onChangeDirectory,
    super.key,
  });

  final String title;
  final List<String> allowedExtensions;
  final Future<void> Function(FilesystemFile) onSelectFile;
  final void Function(FilesystemFile)? onChangeDirectory;

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: NesdAppBar(
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
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  unawaited(_goUpOrClose(context, ref));

                  return null;
                },
              ),
            },
            child: FocusChild(
              autofocus: true,
              wrapAround: true,
              child: Column(
                children: [
                  DirectoryPickerButton(onChangeDirectory: onChangeDirectory),
                  const SearchBox(),
                  FilePickerProgressIndicator(busy: busy),
                  FileList(
                    allowedExtensions: allowedExtensions,
                    onChangeDirectory: onChangeDirectory,
                    onSelectFile: onSelectFile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _goUpOrClose(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final controller = ref.read(filePickerControllerProvider);

    if (!controller.insideEntryDirectory) {
      await navigator.maybePop();

      return;
    }

    final parent = await controller.goUp();

    if (parent != null) {
      onChangeDirectory?.call(parent);

      return;
    }

    await navigator.maybePop();
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
  const FilePickerProgressIndicator({required this.busy, super.key});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filePickerStateProvider);

    final loading = busy || (state is FilePickerData && state.refreshing);

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
    final state = ref.watch(filePickerStateProvider);

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
            controller.go(result, isEntryPoint: true);

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
