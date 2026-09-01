import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/letter_jump.dart';
import 'package:path/path.dart' as p;

const _baseTileHeight = 56.0;
const _dividerHeight = 1.0;

/// fixed row height for scrolling automation
const _baseItemExtent = _baseTileHeight + _dividerHeight;

const _indicatorDuration = Duration(milliseconds: 1200);
const _indicatorFadeDuration = Duration(milliseconds: 150);

class FileList extends HookConsumerWidget {
  const FileList({
    required this.allowedExtensions,
    this.onChangeDirectory,
    super.key,
  });

  final List<String> allowedExtensions;
  final void Function(FilesystemFile)? onChangeDirectory;

  bool _enabled(FilesystemFile file) =>
      file.type == FilesystemFileType.directory ||
      allowedExtensions.isEmpty ||
      allowedExtensions.contains(fileExtension(file.path));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);
    final state = ref.watch(filePickerStateProvider);

    final scrollController = useScrollController();

    final itemExtent = MediaQuery.textScalerOf(context).scale(_baseItemExtent);
    final tileHeight = itemExtent - _dividerHeight;

    final data = state is FilePickerData ? state : null;
    final files = data?.files ?? const <FilesystemFile>[];

    final entries = [
      for (final file in files)
        (
          name: p.basename(file.name),
          isDirectory: file.type == FilesystemFileType.directory,
          focusable: _enabled(file),
        ),
    ];

    final focusNodes = useRef(<FocusNode>[]).value;

    while (focusNodes.length <= files.length) {
      focusNodes.add(FocusNode());
    }

    useEffect(() {
      return () {
        for (final node in focusNodes) {
          node.dispose();
        }
      };
    }, const []);

    final focusedIndex = useState<int?>(null);
    final indicatorGroup = useState<String?>(null);
    final indicatorVisible = useState(false);
    final pendingGroup = useRef<String?>(null);
    final hideTimer = useRef<Timer?>(null);

    useEffect(() {
      return () => hideTimer.value?.cancel();
    }, const []);

    void showIndicator() {
      indicatorGroup.value = pendingGroup.value;
      pendingGroup.value = null;
      indicatorVisible.value = true;

      hideTimer.value?.cancel();
      hideTimer.value = Timer(_indicatorDuration, () {
        indicatorVisible.value = false;
      });
    }

    void onTileFocusChange(int index, {required bool hasFocus}) {
      if (hasFocus) {
        focusedIndex.value = index;

        if (index > 0) {
          showIndicator();
        }
      } else if (focusedIndex.value == index) {
        focusedIndex.value = null;
      }
    }

    bool focusTileAt(int index) {
      if (!scrollController.hasClients) {
        return false;
      }

      final position = scrollController.position;
      final targetTop = index * itemExtent;
      final targetBottom = targetTop + itemExtent;

      final visible =
          targetTop >= position.pixels &&
          targetBottom <= position.pixels + position.viewportDimension;

      if (!visible) {
        scrollController.jumpTo(
          (targetTop - (position.viewportDimension - itemExtent) / 2).clamp(
            0.0,
            position.maxScrollExtent,
          ),
        );
      }

      focusNodes[index].requestFocus();

      return true;
    }

    void jump({required bool forward}) {
      if (entries.isEmpty) {
        return;
      }

      final current = focusedIndex.value;
      final entryIndex = current == null ? -1 : current - 1;
      final direction = forward ? 1 : -1;

      int? target;
      String? group;

      if (controller.textEditingController.text.isNotEmpty) {
        final page = scrollController.hasClients
            ? max(1, scrollController.position.viewportDimension ~/ itemExtent)
            : 1;

        final raw = (entryIndex + direction * page).clamp(
          0,
          entries.length - 1,
        );

        target =
            nearestFocusable(entries, raw, direction: direction) ??
            nearestFocusable(entries, raw, direction: -direction);
      } else {
        final result = letterJump(
          entries,
          currentIndex: entryIndex,
          forward: forward,
        );

        target = result?.index;
        group = result?.group;
      }

      if (target == null) {
        if (!forward && entryIndex >= 0 && focusTileAt(0)) {
          pendingGroup.value = null;
        }

        return;
      }

      if (focusTileAt(target + 1)) {
        pendingGroup.value = group != null && group.isNotEmpty ? group : null;
      }
    }

    final lastDirectoryPath = useRef<String?>(null);

    useEffect(() {
      if (data == null || data.refreshing) {
        return null;
      }

      final path = data.directory.path;

      if (lastDirectoryPath.value == path) {
        return null;
      }

      final isFirstDirectory = lastDirectoryPath.value == null;

      lastDirectoryPath.value = path;

      final pendingPath = controller.takePendingFocusPath();

      if (isFirstDirectory && pendingPath == null) {
        return null;
      }

      var target = 0;

      if (pendingPath != null) {
        final index = files.indexWhere((file) => file.path == pendingPath);

        target = index >= 0 ? index + 1 : 0;
      } else {
        final first = nearestFocusable(entries, 0, direction: 1);

        target = first != null ? first + 1 : 0;
      }

      final focusTarget = target;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          focusTileAt(focusTarget);
        }
      });

      return null;
    }, [state]);

    return Expanded(
      child: Stack(
        children: [
          Actions(
            actions: {
              PreviousTabIntent: CallbackAction<PreviousTabIntent>(
                onInvoke: (_) {
                  jump(forward: false);

                  return null;
                },
              ),
              NextTabIntent: CallbackAction<NextTabIntent>(
                onInvoke: (_) {
                  jump(forward: true);

                  return null;
                },
              ),
            },
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
                  FilePickerData(directory: final directory) =>
                    SliverFixedExtentList(
                      itemExtent: itemExtent,
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tile = index == 0
                            ? ParentTile(
                                directory: directory,
                                focusNode: focusNodes[0],
                                onFocusChange: (hasFocus) =>
                                    onTileFocusChange(0, hasFocus: hasFocus),
                                onChangeDirectory: onChangeDirectory,
                              )
                            : _fileTile(
                                index,
                                files[index - 1],
                                focusNodes,
                                onTileFocusChange,
                              );

                        return Column(
                          children: [
                            SizedBox(height: tileHeight, child: tile),
                            if (index < files.length)
                              const Divider(height: _dividerHeight),
                          ],
                        );
                      }, childCount: files.length + 1),
                    ),
                },
              ],
            ),
          ),
          if (focusedIndex.value case final index?
              when index > 0 && index <= files.length)
            _PositionIndicator(
              visible: indicatorVisible.value,
              group: indicatorGroup.value,
              position: index,
              total: files.length,
            ),
        ],
      ),
    );
  }

  FileTile _fileTile(
    int index,
    FilesystemFile file,
    List<FocusNode> focusNodes,
    void Function(int, {required bool hasFocus}) onTileFocusChange,
  ) {
    return FileTile(
      enabled: _enabled(file),
      isDirectory: file.type == FilesystemFileType.directory,
      file: file,
      fileIsZip: isZipFile(file.path),
      focusNode: focusNodes[index],
      onFocusChange: (hasFocus) => onTileFocusChange(index, hasFocus: hasFocus),
      onChangeDirectory: onChangeDirectory,
    );
  }
}

class ParentTile extends ConsumerWidget {
  const ParentTile({
    required this.directory,
    this.focusNode,
    this.onFocusChange,
    this.onChangeDirectory,
    super.key,
  });

  final FilesystemFile directory;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    return FocusOnHover(
      onFocusChange: onFocusChange,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            focusNode: focusNode,
            leading: Icon(
              Icons.drive_folder_upload_rounded,
              color: focused ? colorScheme.onPrimary : colorScheme.primary,
            ),
            title: Text(
              'Up a directory',
              style: TextStyle(color: focused ? colorScheme.onPrimary : null),
            ),
            onTap: () async {
              final parent = await controller.goUp();

              if (parent != null) {
                onChangeDirectory?.call(parent);
              }
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
    this.focusNode,
    this.onFocusChange,
    this.onChangeDirectory,
    super.key,
  });

  final bool isDirectory;
  final bool enabled;
  final FilesystemFile file;
  final bool fileIsZip;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final void Function(FilesystemFile)? onChangeDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(filePickerControllerProvider);

    return FocusOnHover(
      onFocusChange: onFocusChange,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final colorScheme = Theme.of(context).colorScheme;

          return ListTile(
            focusNode: focusNode,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _PositionIndicator extends StatelessWidget {
  const _PositionIndicator({
    required this.visible,
    required this.group,
    required this.position,
    required this.total,
  });

  final bool visible;
  final String? group;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: 24,
      bottom: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: _indicatorFadeDuration,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group case final group?)
                  Text(
                    group,
                    style: TextStyle(
                      fontSize: 32,
                      color: colorScheme.primary,
                      fontVariations: const [FontVariation.weight(700)],
                    ),
                  ),
                Text('$position / $total'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
