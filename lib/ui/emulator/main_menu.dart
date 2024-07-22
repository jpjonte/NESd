import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
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

    return FocusChild(
      autofocus: true,
      child: Center(
        child: NesdMenuWrapper(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RecentRomList(),
              if (settings.recentRomPaths.isNotEmpty)
                const NesdVerticalDivider(),
              NesdButton(
                onPressed: () async {
                  final directory = await _getRomPath(settings);

                  if (!context.mounted) {
                    return;
                  }

                  final path = await AutoRouter.of(context).push<String?>(
                    FilePickerRoute(
                      title: 'Select a ROM',
                      initialDirectory: directory.path,
                      type: FilePickerType.file,
                      allowedExtensions: const ['.nes', '.zip'],
                    ),
                  );

                  if (path != null) {
                    controller.loadRom(path);
                  }
                },
                child: const Text('Open ROM'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () =>
                    ref.read(routerProvider).navigate(const SettingsRoute()),
                child: const Text('Settings'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const AboutDialog(),
                ),
                child: const Text('About'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () =>
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                child: const Text('Quit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Directory> _getRomPath(Settings settings) async {
    final lastRomPath = settings.lastRomPath;

    if (lastRomPath == null) {
      return getApplicationDocumentsDirectory();
    }

    final lastRomDirectory = Directory(lastRomPath);

    if (!lastRomDirectory.existsSync()) {
      return getApplicationDocumentsDirectory();
    }

    return lastRomDirectory;
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

    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) => const Divider(),
      itemCount: settings.recentRomPaths.length,
      itemBuilder: (context, index) {
        final path = settings.recentRomPaths[index];

        return FocusOnHover(
          child: ListTile(
            leading: Icon(
              Icons.videogame_asset,
              color: nesdRed[500],
            ),
            title: Text(p.basename(path)),
            onTap: () => controller.loadRom(path),
          ),
        );
      },
    );
  }
}
