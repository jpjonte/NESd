import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/common/separated_column.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/file_system_file.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MainMenu extends ConsumerWidget {
  const MainMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(nesControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final filesystem = ref.watch(fileSystemProvider);

    return FocusChild(
      autofocus: true,
      child: Center(
        child: NesdMenuWrapper(
          child: ListView(
            children: [
              const RecentRomList(),
              if (settings.recentRomPaths.isNotEmpty)
                const NesdVerticalDivider(),
              Center(
                child: NesdButton(
                  onPressed: () async {
                    final directory = await _getRomPath(filesystem, settings);

                    if (!context.mounted) {
                      return;
                    }

                    final file =
                        await AutoRouter.of(context).push<FileSystemFile?>(
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
              ),
              const NesdVerticalDivider(),
              Center(
                child: NesdButton(
                  onPressed: () =>
                      ref.read(routerProvider).navigate(const SettingsRoute()),
                  child: const Text('Settings'),
                ),
              ),
              const NesdVerticalDivider(),
              Center(
                child: NesdButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AboutDialog(),
                  ),
                  child: const Text('About'),
                ),
              ),
              const NesdVerticalDivider(),
              Center(
                child: NesdButton(
                  onPressed: () => quit(),
                  child: const Text('Quit'),
                ),
              ),
            ],
          ),
        ),
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

class RecentRomList extends ConsumerWidget {
  const RecentRomList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    final controller = ref.read(nesControllerProvider);

    return SeparatedColumn(
      separatorBuilder: (index) => const Divider(),
      children: [
        for (final path in settings.recentRomPaths)
          FocusOnHover(
            child: ListTile(
              leading: Icon(
                Icons.videogame_asset,
                color: nesdRed[500],
              ),
              title: Text(p.basename(path)),
              onTap: () => controller.loadRom(path),
            ),
          ),
      ],
    );
  }
}
