import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/common/context_menu.dart';
import 'package:nesd/ui/common/custom_button.dart';
import 'package:nesd/ui/common/outline_text.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/theme/base.dart';

const gameTileWidth = 272.0;
const gameTileHeight = 256.0;

const thumbnailWidth = 256.0;
const thumbnailHeight = 240.0;

sealed class RomThumbnail {
  const RomThumbnail();
}

@immutable
class DecodedThumbnail extends RomThumbnail {
  const DecodedThumbnail(this.image);

  final ui.Image image;
}

@immutable
class StoredThumbnail extends RomThumbnail {
  const StoredThumbnail();
}

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
  final RomThumbnail? thumbnail;
  final NESState? state;
  final int? slot;
}

Future<ui.Image?> loadStoredThumbnail(File file) async {
  if (!file.existsSync()) {
    return null;
  }

  try {
    final bytes = await file.readAsBytes();

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    final codec = await descriptor.instantiateCodec();

    final frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  } on Exception {
    return null;
  }
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
        builder: (_, active) => SizedBox(
          width: gameTileWidth,
          height: gameTileHeight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Container(
                  width: thumbnailWidth,
                  height: thumbnailHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? nesdRed : Theme.of(context).disabledColor,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: switch (romTileData.thumbnail) {
                      DecodedThumbnail(:final image) => _Thumbnail(
                        image: image,
                      ),
                      StoredThumbnail() => _StoredThumbnail(
                        romTileData: romTileData,
                      ),
                      null => const _Thumbnail(),
                    },
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
                              fontVariations: const [FontVariation.weight(700)],
                              color: Colors.white,
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
                        padding: const EdgeInsets.all(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.close),
                            padding: const EdgeInsets.all(4),
                            color: Colors.white,
                            onPressed: onRemove,
                          ),
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

class _StoredThumbnail extends HookConsumerWidget {
  const _StoredThumbnail({required this.romTileData});

  final RomTileData romTileData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final romManager = ref.watch(romManagerProvider);

    final loading = useMemoized(
      () =>
          loadStoredThumbnail(romManager.getThumbnailFile(romTileData.romInfo)),
      [romTileData],
    );

    // useFuture keeps the previous image while a new one is loading, so
    // returning to the ROM list does not blank out the tile
    final snapshot = useFuture(loading);

    return _Thumbnail(image: snapshot.data);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.image});

  final ui.Image? image;

  @override
  Widget build(BuildContext context) => RawImage(
    width: thumbnailWidth,
    height: thumbnailHeight,
    filterQuality: FilterQuality.none,
    image: image,
  );
}
