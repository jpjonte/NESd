import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/dividers.dart';
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
  static const aboutKey = Key('about');
  static const quitKey = Key('quit');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(initialRomProvider, (_, initialRom) {
      if (initialRom != null) {
        scheduleMicrotask(() {
          ref.read(nesControllerProvider).loadRom(initialRom);
          ref.read(routerProvider).navigate(const EmulatorRoute());
          ref.read(initialRomProvider.notifier).clear();
        });
      }
    });

    return const FocusChild(
      autofocus: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                RecentRomList(),
                OpenRomButton(key: openRomKey),
                NesdVerticalDivider(),
                SettingsButton(key: settingsKey),
                NesdVerticalDivider(),
                AboutButton(key: aboutKey),
                NesdVerticalDivider(),
                QuitButton(key: quitKey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OpenRomButton extends ConsumerWidget {
  const OpenRomButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final filesystem = ref.watch(filesystemProvider);

    return Center(
      child: NesdButton(
        onPressed: () async {
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
              // TODO store whole FilesystemFile in settings
              onChangeDirectory:
                  (directory) =>
                      settingsController.lastRomPath = directory.path,
            ),
          );

          if (file != null) {
            controller.loadRom(file.path);
            ref.read(routerProvider).navigate(const EmulatorRoute());
          }
        },
        child: const Text('Open ROM'),
      ),
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

      if (!(await filesystem.isDirectory(lastRomPath)) &&
          !(await filesystem.exists(lastRomPath))) {
        final result = await filesystem.getDocumentsDirectory();

        if (result == null) {
          return null;
        }

        return result;
      }
    } on NesdException {
      settingsController.lastRomPath = null;

      return null;
    }

    return FilesystemFile(
      path: lastRomPath,
      name: '',
      type: FilesystemFileType.directory,
    );
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: NesdButton(
        onPressed:
            () => ref.read(routerProvider).navigate(const SettingsRoute()),
        child: const Text('Settings'),
      ),
    );
  }
}

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NesdButton(
        onPressed:
            () => showDialog(
              context: context,
              builder: (context) => const AboutDialog(),
            ),
        child: const Text('About'),
      ),
    );
  }
}

class QuitButton extends StatelessWidget {
  const QuitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NesdButton(
        onPressed: () => quit(),
        child: const Text('Quit NESd'),
      ),
    );
  }
}
