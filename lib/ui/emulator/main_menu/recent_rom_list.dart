import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
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

    if (recentRoms.isEmpty) {
      return Center(
        child: SizedBox(
          key: logoKey,
          width: 256,
          height: 256,
          child: Image.asset('assets/logo.png'),
        ),
      );
    }

    final future = useMemoized(
      () => _getRomTileDataForRoms(romManager, recentRoms),
      [recentRoms],
    );

    final romsSnapshot = useFuture(future);

    if (romsSnapshot.hasError) {
      return const Center(child: Text('Error loading ROMs'));
    }

    if (!romsSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final roms = romsSnapshot.data!;

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

    return PaginatedGrid(
      skipRows: 1, // skip 1 row to leave room for menu
      children: [
        for (final romTileData in roms)
          RomTile(
            onPressed: () async {
              final success = await controller.loadRom(
                romTileData.romInfo.path!,
              );

              if (success || !context.mounted) {
                return;
              }

              final confirmed = await ConfirmationDialog.show(
                context,
                title: const Text('Remove ROM?'),
                content: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(text: 'The ROM '),
                      TextSpan(
                        text: romTileData.romInfo.path,
                        style: DefaultTextStyle.of(
                          context,
                        ).style.copyWith(fontWeight: FontWeight.w900),
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
            contextMenuBuilder:
                (context, close) => [
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
    );
  }

  Future<List<RomTileData>> _getRomTileDataForRoms(
    RomManager romManager,
    List<RomInfo> romInfos,
  ) async {
    return [
      for (final romInfo in romInfos) await romManager.getRomTileData(romInfo),
    ];
  }
}
