import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/ui/common/context_menu.dart';
import 'package:nesd/ui/common/custom_button.dart';
import 'package:nesd/ui/common/outline_text.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/nesd_theme.dart';

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

class RomTile extends ConsumerWidget {
  const RomTile({
    required this.romTileData,
    required this.onPressed,
    this.onRemove,
    this.contextMenuBuilder,
    super.key,
  });

  final RomTileData romTileData;
  final VoidCallback onPressed;
  final VoidCallback? onRemove;
  final ContextMenuBuilder? contextMenuBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContextMenu(
      contextMenuBuilder: contextMenuBuilder,
      child: CustomButton(
        onPressed: onPressed,
        builder:
            (_, active) => SizedBox(
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
                                style: baseTextStyle.copyWith(
                                  fontSize: 15,
                                  fontVariations: const [
                                    FontVariation.weight(700),
                                  ],
                                ),
                                strokeWidth: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onRemove case final onRemove?)
                      ExcludeFocus(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              onPressed: onRemove,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
