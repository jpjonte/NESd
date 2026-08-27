import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/main_menu/recent_rom_list.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_menu.g.dart';

@riverpod
class InitialRom extends _$InitialRom {
  InitialRom({this.initialValue});

  final String? initialValue;

  @override
  String? build() => initialValue;

  void clear() {
    state = null;
  }
}

class MainMenu extends HookConsumerWidget {
  const MainMenu({super.key});

  static const openRomKey = Key('openRom');
  static const settingsKey = Key('settings');
  static const quitKey = Key('quit');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final subscription = ref.listenManual(initialRomProvider, (
        _,
        initialRom,
      ) {
        if (initialRom != null) {
          scheduleMicrotask(() => _startInitialRom(ref, initialRom));
        }
      }, fireImmediately: true);

      return subscription.close;
    }, const []);

    return FocusChild(
      autofocus: true,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Flexible(child: RecentRomList()),
            OverflowBar(
              alignment: MainAxisAlignment.center,
              overflowAlignment: OverflowBarAlignment.center,
              spacing: 16,
              overflowSpacing: 16,
              children: [
                const OpenRomButton(key: openRomKey),
                const SettingsButton(key: settingsKey),
                // Can't quit on web, and Android apps background instead of
                // quitting.
                if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android)
                  const QuitButton(key: quitKey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startInitialRom(WidgetRef ref, String initialRom) {
    unawaited(
      ref
          .read(nesControllerProvider)
          .startRom(
            FilesystemFile(
              path: initialRom,
              name: p.basename(initialRom),
              type: FilesystemFileType.file,
            ),
          ),
    );

    ref.read(initialRomProvider.notifier).clear();
  }
}

class OpenRomButton extends ConsumerWidget {
  const OpenRomButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final filesystem = ref.watch(filesystemProvider);

    return NesdButton(
      onPressed: () async {
        if (kIsWeb) {
          await controller.selectRom();

          return;
        }

        final directory = await _getRomPath(filesystem, settingsController);

        if (directory == null) {
          return;
        }

        if (!context.mounted) {
          return;
        }

        final file = await AutoRouter.of(context).push<FilesystemFile?>(
          FilePickerRoute(
            title: 'Select a ROM',
            initialDirectory: directory,
            type: FilePickerType.file,
            allowedExtensions: const ['.nes', '.zip'],
            onChangeDirectory: (directory) =>
                settingsController.lastRomPath = directory,
          ),
        );

        if (file != null) {
          await controller.startRom(file);
        }
      },
      child: const Text('Open ROM'),
    );
  }

  Future<FilesystemFile?> _getRomPath(
    Filesystem filesystem,
    SettingsController settingsController,
  ) async {
    final lastRomPath = settingsController.lastRomPath;

    try {
      if (lastRomPath == null) {
        final result = await filesystem.getDocumentsDirectory();

        if (result == null) {
          return null;
        }

        return result;
      }

      if (!(await filesystem.isDirectory(lastRomPath.path)) &&
          !(await filesystem.exists(lastRomPath.path))) {
        final result = await filesystem.getDocumentsDirectory();

        if (result == null) {
          return null;
        }

        return result;
      }
    } on NesdException catch (e) {
      log.storage.warning(
        'Could not resolve the startup directory. Forgetting the last path',
        context: {if (lastRomPath != null) 'lastRomPath': lastRomPath.path},
        error: e,
      );

      settingsController.lastRomPath = null;

      return null;
    }

    return lastRomPath;
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NesdButton(
      onPressed: () => ref.read(routerProvider).navigate(const SettingsRoute()),
      child: const Text('Settings'),
    );
  }
}

class QuitButton extends StatelessWidget {
  const QuitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NesdButton(onPressed: () => quit(), child: const Text('Quit NESd'));
  }
}
