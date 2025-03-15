import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/util/decorate.dart';

const gameTileWidth = 272.0;
const gameTileHeight = 256.0;

class RomTileData {
  const RomTileData({
    required this.romInfo,
    required this.title,
    this.thumbnail,
    this.state,
    this.slot,
  });

  final RomInfo romInfo;
  final String title;
  final ui.Image? thumbnail;
  final NESState? state;
  final int? slot;
}

typedef RomContextMenuBuilder =
    List<Widget> Function(
      BuildContext context,
      RomTileData romTileData,
      VoidCallback close,
    );

class RomList extends HookConsumerWidget {
  const RomList({
    required this.roms,
    required this.onPressed,
    this.onRemove,
    this.contextMenuBuilder,
    this.skipRows = 0,
    super.key,
  });

  final List<RomTileData> roms;
  final int skipRows;
  final void Function(RomTileData) onPressed;
  final void Function(RomTileData)? onRemove;
  final RomContextMenuBuilder? contextMenuBuilder;

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
              child:
                  page.value > 0
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
                          onRemove: decorate(
                            onRemove,
                            (onRemove) => () => onRemove(romTileData),
                          ),
                          contextMenuBuilder: decorate(
                            contextMenuBuilder,
                            (builder) =>
                                (context, close) =>
                                    builder(context, romTileData, close),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            SizedBox(
              width: 40,
              height: rowCount * gameTileHeight,
              child:
                  page.value < pages - 1
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
