import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/rom_tile.dart';

const _gutterWidth = 40.0;

class PaginatedGrid extends HookConsumerWidget {
  const PaginatedGrid({
    this.tileWidth = gameTileWidth,
    this.tileHeight = gameTileHeight,
    this.skipRows = 0,
    this.children = const [],
    super.key,
  });

  final List<Widget> children;
  final int skipRows;

  final double tileWidth;
  final double tileHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(0);

    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = min(mediaQuery.size.width, constraints.maxWidth);
        final height = min(mediaQuery.size.height, constraints.maxHeight);

        final columnCount = max(1, (available - 2 * _gutterWidth) ~/ tileWidth);
        final rowCount = max(1, height ~/ tileHeight - skipRows);

        final gutter = min(
          _gutterWidth,
          max(0.0, (available - columnCount * tileWidth) / 2),
        );

        final count = columnCount * rowCount;

        final pages = count > 0 ? (children.length / count).ceil() : 1;

        final currentPage = page.value.clamp(0, pages - 1);

        final romPaths = children
            .skip(currentPage * count)
            .take(count)
            .toList();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: gutter,
              height: rowCount * tileHeight,
              child: currentPage > 0
                  ? InkWell(
                      onTap: () => page.value = currentPage - 1,
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
                    children: row,
                  ),
              ],
            ),
            SizedBox(
              width: gutter,
              height: rowCount * tileHeight,
              child: currentPage < pages - 1
                  ? InkWell(
                      onTap: () => page.value = currentPage + 1,
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
