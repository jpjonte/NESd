import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
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

const _spinnerDelay = Duration(milliseconds: 150);

const _fadeDuration = Duration(milliseconds: 200);

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

Future<ui.Image?> loadStoredThumbnail(Uint8List? bytes) async {
  if (bytes == null) {
    return null;
  }

  try {
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
  static const thumbnailFadeKey = Key('thumbnailFade');

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
      () => romManager
          .readThumbnail(romTileData.romInfo)
          .then(loadStoredThumbnail)
          .onError((error, _) {
            log.rom.warning('Failed to load thumbnail', error: error);

            return null;
          }),
      [romTileData],
    );

    // useFuture keeps the previous image while a new one is loading, so
    // returning to the ROM list does not blank out the tile
    final snapshot = useFuture(loading);

    final romPath = romTileData.romInfo.file.path;

    final startedAt = useMemoized(
      () => WidgetsBinding.instance.currentFrameTimeStamp,
      [romPath],
    );

    final wakeUp = useState(0);

    useEffect(() {
      final timer = Timer(_spinnerDelay, () => wakeUp.value++);

      return timer.cancel;
    }, [romPath]);

    final loaded = snapshot.connectionState != ConnectionState.waiting;

    final elapsed = WidgetsBinding.instance.currentFrameTimeStamp - startedAt;

    return Stack(
      alignment: Alignment.center,
      children: [
        _Thumbnail(image: snapshot.data),
        if (!loaded && elapsed >= _spinnerDelay)
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.image});

  final ui.Image? image;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    key: RomTile.thumbnailFadeKey,
    opacity: image == null ? 0 : 1,
    duration: _fadeDuration,
    child: RawImage(
      width: thumbnailWidth,
      height: thumbnailHeight,
      filterQuality: FilterQuality.none,
      image: image,
    ),
  );
}
