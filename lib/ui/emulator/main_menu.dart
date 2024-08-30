import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/main_menu/recent_rom_list.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:nesd/ui/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path_provider/path_provider.dart';

class MainMenu extends ConsumerWidget {
  const MainMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return FocusChild(
      autofocus: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              const RecentRomList(),
              if (settings.recentRomPaths.isNotEmpty)
                const NesdVerticalDivider(),
              const OpenRomButton(),
              const NesdVerticalDivider(),
              const SettingsButton(),
              const NesdVerticalDivider(),
              const AboutButton(),
              const NesdVerticalDivider(),
              const QuitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class OpenRomButton extends ConsumerWidget {
  const OpenRomButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final filesystem = ref.watch(fileSystemProvider);

    return Center(
      child: NesdButton(
        onPressed: () async {
          final settings = ref.watch(settingsControllerProvider);
          final directory = await _getRomPath(filesystem, settings);

          if (!context.mounted) {
            return;
          }

          final file = await AutoRouter.of(context).push<FileSystemFile?>(
            FilePickerRoute(
              title: 'Select a ROM',
              initialDirectory: directory.path,
              type: FilePickerType.file,
              allowedExtensions: const ['.nes', '.zip'],
              onChangeDirectory: (directory) {
                settingsController.lastRomPath = directory.path;
              },
            ),
          );

          if (file != null) {
            controller.loadRom(file.path);
          }
        },
        child: const Text('Open ROM'),
      ),
    );
  }

  Future<Directory> _getRomPath(
    FileSystem filesystem,
    Settings settings,
  ) async {
    final lastRomPath = settings.lastRomPath;

    if (lastRomPath == null) {
      return getApplicationDocumentsDirectory();
    }

    if (!(await filesystem.exists(lastRomPath))) {
      return getApplicationDocumentsDirectory();
    }

    return Directory(lastRomPath);
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: NesdButton(
        onPressed: () =>
            ref.read(routerProvider).navigate(const SettingsRoute()),
        child: const Text('Settings'),
      ),
    );
  }
}

class AboutButton extends StatelessWidget {
  const AboutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NesdButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AboutDialog(),
        ),
        child: const Text('About'),
      ),
    );
  }
}

class QuitButton extends StatelessWidget {
  const QuitButton({
    super.key,
  });

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
