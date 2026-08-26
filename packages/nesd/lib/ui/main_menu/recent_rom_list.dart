import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';

class RecentRomList extends HookConsumerWidget {
  static const logoKey = Key('logo');

  const RecentRomList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romManager = ref.watch(romManagerProvider);
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);

    final recentRoms = ref.watch(
      settingsControllerProvider.select((settings) => settings.recentRoms),
    );

    final route = ref.watch(currentRouteProvider);

    if (recentRoms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          key: logoKey,
          width: 256,
          height: 256,
          child: Image.asset('assets/logo.png'),
        ),
      );
    }

    final thumbnailRevision = useValueListenable(romManager.thumbnailRevision);

    // rebuilding the tile data makes the tiles reload their thumbnails, so
    // returning to the list after playing shows the thumbnail just saved
    final roms = useMemoized(
      () => [
        for (final romInfo in recentRoms) romManager.getRomTileData(romInfo),
      ],
      [recentRoms, route == MainRoute.name, thumbnailRevision],
    );

    Future<void> remove(BuildContext context, RomTileData romTileData) async {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: const Text('Remove ROM from list?'),
        content: Text(
          'Are you sure you want to remove ${romTileData.title} from the list?',
        ),
      );

      if (confirmed == true) {
        settingsController.removeRecentRom(romTileData.romInfo);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PaginatedGrid(
        children: [
          for (final romTileData in roms)
            RomTile(
              onPressed: () async {
                final started = await controller.startRom(
                  romTileData.romInfo.file,
                );

                if (started || !context.mounted) {
                  return;
                }

                final theme = Theme.of(context);

                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: Text(
                    'Remove ROM?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontVariations: const [FontVariation.weight(700)],
                    ),
                  ),
                  content: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: 'The ROM '),
                        TextSpan(
                          text: romTileData.romInfo.file.path,
                          style: DefaultTextStyle.of(context).style.copyWith(
                            fontVariations: const [FontVariation.weight(900)],
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const TextSpan(text: ' was not found.'),
                        const TextSpan(
                          text: ' Do you want to remove it from the list?',
                        ),
                      ],
                    ),
                  ),
                );

                if (confirmed == true) {
                  settingsController.removeRecentRom(romTileData.romInfo);
                }
              },
              onRemove: () async => await remove(context, romTileData),
              contextMenuBuilder: (context, close) => [
                ListTile(
                  title: const Text('Save states'),
                  onTap: () {
                    close();
                    ref
                        .read(routerProvider)
                        .navigate(
                          SaveStatesRoute(romInfo: romTileData.romInfo),
                        );
                  },
                ),
                ListTile(
                  title: const Text('Remove from list'),
                  onTap: () async {
                    close();
                    await remove(context, romTileData);
                  },
                ),
              ],
              romTileData: romTileData,
            ),
        ],
      ),
    );
  }
}
