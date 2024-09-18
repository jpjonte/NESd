import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/ui/common/custom_button.dart';
import 'package:nesd/ui/common/outline_text.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/router.dart';
import 'package:nesd/ui/settings/settings.dart';

const gameTileWidth = 272.0;
const gameTileHeight = 256.0;

class RomTileData {
  const RomTileData({
    required this.romInfo,
    required this.title,
    this.thumbnail,
    this.state,
  });

  final RomInfo romInfo;
  final String title;
  final ui.Image? thumbnail;
  final NESState? state;
}

class RecentRomList extends HookConsumerWidget {
  const RecentRomList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romManager = ref.watch(romManagerProvider);
    final controller = ref.read(nesControllerProvider);

    final recentRoms = ref.watch(
      settingsControllerProvider.select((settings) => settings.recentRoms),
    );

    final romsSnapshot = useFuture(
      _getRomTileDataForRoms(romManager, recentRoms),
    );

    if (romsSnapshot.hasError) {
      return const Center(child: Text('Error loading ROMs'));
    }

    if (!romsSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final roms = romsSnapshot.data!;

    return RomList(
      roms: roms,
      skipRows: 1, // skip 1 row to leave room for menu
      onPressed: (romTileData) => controller.loadRom(romTileData.romInfo.path),
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

class RomList extends HookConsumerWidget {
  const RomList({
    required this.roms,
    required this.onPressed,
    this.skipRows = 0,
    super.key,
  });

  final List<RomTileData> roms;
  final int skipRows;
  final void Function(RomTileData) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(0);

    final mediaQuery = MediaQuery.of(context);

    imageCache.clear();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(mediaQuery.size.width, constraints.maxWidth) - 80;
        final height = min(mediaQuery.size.height, constraints.maxHeight);

        final columnCount = width ~/ gameTileWidth;
        final rowCount = max(height ~/ gameTileHeight - skipRows, 1);

        final count = columnCount * rowCount;

        final pages = count > 0 ? (roms.length / count).ceil() : 1;

        final romPaths = roms.skip(page.value * count).take(count).toList();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 40,
              height: rowCount * gameTileHeight,
              child: page.value > 0
                  ? InkWell(
                      onTap: () => page.value--,
                      child: const Icon(Icons.arrow_back_ios),
                    )
                  : const SizedBox(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final row in romPaths.slices(columnCount))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final romTileData in row)
                        RomTile(
                          romTileData: romTileData,
                          onPressed: () => onPressed(romTileData),
                          onLongPress: () => ref.read(routerProvider).navigate(
                                SaveStatesRoute(romInfo: romTileData.romInfo),
                              ),
                        ),
                    ],
                  ),
              ],
            ),
            SizedBox(
              width: 40,
              height: rowCount * gameTileHeight,
              child: page.value < pages - 1
                  ? InkWell(
                      onTap: () => page.value++,
                      child: const Icon(Icons.arrow_forward_ios),
                    )
                  : const SizedBox(),
            ),
          ],
        );
      },
    );
  }
}

class RomTile extends ConsumerWidget {
  const RomTile({
    required this.romTileData,
    required this.onPressed,
    this.onLongPress,
    super.key,
  });

  final RomTileData romTileData;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      builder: (_, active) => SizedBox(
        width: gameTileWidth,
        height: gameTileHeight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Container(
                width: 256,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? nesdRed : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: RawImage(
                    width: 256,
                    height: 240,
                    filterQuality: FilterQuality.none,
                    image: romTileData.thumbnail,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 36,
                      width: double.infinity,
                      color: Colors.black.withAlpha(150),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: StrokeText(
                          romTileData.title,
                          style: const TextStyle(fontSize: 15),
                          strokeWidth: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
