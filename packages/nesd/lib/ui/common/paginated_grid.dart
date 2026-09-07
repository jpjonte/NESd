import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/paginated_grid_controller.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';

const _gutterWidth = 40.0;

class PaginatedGrid extends HookConsumerWidget {
  const PaginatedGrid({
    this.tileWidth = gameTileWidth,
    this.tileHeight = gameTileHeight,
    this.children = const [],
    this.controller,
    super.key,
  });

  final List<Widget> children;

  final PaginatedGridController? controller;

  final double tileWidth;
  final double tileHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownController = usePaginatedGridController();

    final pageController = controller ?? ownController;

    useListenable(pageController);

    final tilesFocusNode = useFocusNode();

    useEffect(() {
      void focusNewPage() => WidgetsBinding.instance.addPostFrameCallback(
        (_) => focusFirstDescendant(tilesFocusNode),
      );

      pageController.addListener(focusNewPage);

      return () => pageController.removeListener(focusNewPage);
    }, [pageController]);

    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = min(mediaQuery.size.width, constraints.maxWidth);
        final height = min(mediaQuery.size.height, constraints.maxHeight);

        final columnCount = max(1, (available - 2 * _gutterWidth) ~/ tileWidth);
        final rowCount = max(1, height ~/ tileHeight);

        final gutter = min(
          _gutterWidth,
          max(0.0, (available - columnCount * tileWidth) / 2),
        );

        final count = columnCount * rowCount;

        // at least one page, even with no children
        final pages = count > 0 ? max(1, (children.length / count).ceil()) : 1;

        pageController.pageCount = pages;

        final currentPage = pageController.page;

        final romPaths = children
            .skip(currentPage * count)
            .take(count)
            .toList();

        final visibleRows = romPaths.slices(columnCount).toList();

        return PaginatedGridActions(
          controller: pageController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: gutter,
                height: visibleRows.length * tileHeight,
                child: currentPage > 0
                    ? InkWell(
                        onTap: pageController.previousPage,
                        child: const Icon(Icons.arrow_back_ios),
                      )
                    : const SizedBox(),
              ),
              Focus(
                focusNode: tilesFocusNode,
                canRequestFocus: false,
                skipTraversal: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in visibleRows)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row,
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: gutter,
                height: visibleRows.length * tileHeight,
                child: currentPage < pages - 1
                    ? InkWell(
                        onTap: pageController.nextPage,
                        child: const Icon(Icons.arrow_forward_ios),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaginatedGridActions extends StatelessWidget {
  const PaginatedGridActions({
    required this.controller,
    required this.child,
    super.key,
  });

  final PaginatedGridController controller;

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      PreviousTabIntent: CallbackAction<PreviousTabIntent>(
        onInvoke: (_) {
          controller.previousPage();

          return null;
        },
      ),
      NextTabIntent: CallbackAction<NextTabIntent>(
        onInvoke: (_) {
          controller.nextPage();

          return null;
        },
      ),
    },
    child: child,
  );
}
