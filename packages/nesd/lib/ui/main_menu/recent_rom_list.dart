import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/logo.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/paginated_grid_controller.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';

List<RomInfo> mainMenuRoms(List<RomInfo> favorites, List<RomInfo> recents) => [
  ...favorites,
  ...recents.where((recent) => !favorites.any((f) => f.sameRom(recent))),
];

class RecentRomList extends HookConsumerWidget {
  static const logoKey = Key('logo');

  const RecentRomList({
    required this.gridController,
    required this.startingRom,
    super.key,
  });

  final PaginatedGridController gridController;
  final ValueNotifier<RomInfo?> startingRom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romManager = ref.watch(romManagerProvider);
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final actionHandler = ref.read(actionHandlerProvider);

    final recentRoms = ref.watch(
      settingsControllerProvider.select((settings) => settings.recentRoms),
    );

    final favoriteRoms = ref.watch(
      settingsControllerProvider.select((settings) => settings.favoriteRoms),
    );

    if (recentRoms.isEmpty && favoriteRoms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          key: logoKey,
          width: 256,
          height: 256,
          child: Image.asset(logoAsset),
        ),
      );
    }

    final thumbnailRevision = useValueListenable(romManager.thumbnailRevision);

    final roms = useMemoized(
      () => [
        for (final romInfo in mainMenuRoms(favoriteRoms, recentRoms))
          (
            data: romManager.getRomTileData(romInfo),
            favorite: favoriteRoms.any((f) => f.sameRom(romInfo)),
          ),
      ],
      [favoriteRoms, recentRoms, thumbnailRevision],
    );

    void toggleFavorite(RomInfo romInfo, {required bool favorite}) {
      if (favorite) {
        settingsController.removeFavorite(romInfo);

        return;
      }

      settingsController.addFavorite(romInfo);
    }

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
        controller: gridController,
        children: [
          for (final (data: romTileData, :favorite) in roms)
            RomTile(
              loading:
                  startingRom.value?.file.path == romTileData.romInfo.file.path,
              onPressed: () async {
                if (startingRom.value != null) {
                  return;
                }

                startingRom.value = romTileData.romInfo;

                actionHandler.enabled = false;

                final bool started;

                try {
                  started = await controller.startRom(romTileData.romInfo.file);
                } finally {
                  actionHandler.enabled = true;

                  if (context.mounted) {
                    startingRom.value = null;
                  }
                }

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
                  settingsController
                    ..removeRecentRom(romTileData.romInfo)
                    ..removeFavorite(romTileData.romInfo);
                }
              },
              onRemove: favorite
                  ? null
                  : () async => await remove(context, romTileData),
              favorite: favorite,
              onToggleFavorite: () =>
                  toggleFavorite(romTileData.romInfo, favorite: favorite),
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
                  title: Text(
                    favorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                  onTap: () {
                    close();
                    toggleFavorite(romTileData.romInfo, favorite: favorite);
                  },
                ),
                if (!favorite)
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
