import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/outline_text.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:path/path.dart' as p;

const gameTileWidth = 272.0;
const gameTileHeight = 256.0;

class RecentRomList extends HookConsumerWidget {
  const RecentRomList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(nesControllerProvider)
      ..watch(romManagerProvider);

    final page = useState(0);

    final recentRoms = ref.watch(
      settingsControllerProvider.select((settings) => settings.recentRoms),
    );

    final mediaQuery = MediaQuery.of(context);

    imageCache.clear();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(mediaQuery.size.width, constraints.maxWidth) - 80;
        final height = min(mediaQuery.size.height, constraints.maxHeight);

        final columnCount = width ~/ gameTileWidth;
        final rowCount = max(
          height ~/ gameTileHeight - 1, // skip 1 row to leave room for menu
          1,
        );

        final count = columnCount * rowCount;

        final pages = (recentRoms.length / count).ceil();

        final romPaths =
            recentRoms.skip(page.value * count).take(count).toList();

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
                      for (final romInfo in row) RomTile(romInfo: romInfo),
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

class RomTile extends HookConsumerWidget {
  const RomTile({
    required this.romInfo,
    super.key,
  });

  final RomInfo romInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = useState(false);

    final controller = ref.read(nesControllerProvider);

    final romManager = ref.read(romManagerProvider);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) => controller.loadRom(romInfo.path),
        ),
      },
      child: FocusOnHover(
        cursor: SystemMouseCursors.click,
        onFocusChange: (hasFocus) => active.value = hasFocus,
        child: Focus(
          child: GestureDetector(
            onTap: () => controller.loadRom(romInfo.path),
            child: SizedBox(
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
                          color: active.value ? nesdRed : Colors.grey[600]!,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          width: 256,
                          height: 240,
                          filterQuality: FilterQuality.none,
                          romManager.getThumbnailFile(romInfo),
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const SizedBox();
                          },
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
                                p.basenameWithoutExtension(romInfo.path),
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
          ),
        ),
      ),
    );
  }
}
