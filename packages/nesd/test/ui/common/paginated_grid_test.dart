import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/paginated_grid_controller.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';

Widget _tile(int index) => SizedBox(
  key: ValueKey('tile$index'),
  width: gameTileWidth,
  height: gameTileHeight,
);

void main() {
  Future<void> pumpGrid(
    WidgetTester tester, {
    required double width,
    required int tileCount,
    double height = 800,
    Widget Function(int index) tileBuilder = _tile,
    PaginatedGridController? controller,
  }) async {
    tester.view.physicalSize =
        const Size(2000, 1400) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: height,
                child: PaginatedGrid(
                  controller: controller,
                  children: [
                    for (var i = 0; i < tileCount; i++) tileBuilder(i),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('narrower than one tile plus both arrow gutters', () {
    testWidgets('lays out without overflowing', (tester) async {
      await pumpGrid(tester, width: 344, tileCount: 1);

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the tile at its natural size', (tester) async {
      await pumpGrid(tester, width: 344, tileCount: 1);

      expect(
        tester.getSize(find.byKey(const ValueKey('tile0'))).width,
        gameTileWidth,
      );
    });

    testWidgets('keeps the tile inside the grid bounds', (tester) async {
      await pumpGrid(tester, width: 344, tileCount: 1);

      final rect = tester.getRect(find.byKey(const ValueKey('tile0')));

      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(344));
    });
  });

  testWidgets('lays out at the exact fitting width', (tester) async {
    await pumpGrid(tester, width: 352, tileCount: 1);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('tile0'))).width,
      gameTileWidth,
    );
  });

  testWidgets('still fits four columns when there is room', (tester) async {
    await pumpGrid(tester, width: 1200, tileCount: 8);

    expect(tester.takeException(), isNull);

    final firstRowY = tester.getTopLeft(find.byKey(const ValueKey('tile0'))).dy;

    final sameRow = [
      for (var i = 0; i < 8; i++)
        if (tester.getTopLeft(find.byKey(ValueKey('tile$i'))).dy == firstRowY)
          i,
    ];

    expect(sameRow, [0, 1, 2, 3]);
  });

  group('paging with the tab intents', () {
    Future<Map<int, FocusNode>> pumpPagedGrid(
      WidgetTester tester, {
      PaginatedGridController? controller,
    }) async {
      final nodes = <int, FocusNode>{};

      FocusNode nodeFor(int index) => nodes.putIfAbsent(index, () {
        final node = FocusNode(debugLabel: 'tile$index');

        addTearDown(node.dispose);

        return node;
      });

      await pumpGrid(
        tester,
        width: 700,
        height: 300,
        tileCount: 5,
        controller: controller,
        tileBuilder: (index) => SizedBox(
          key: ValueKey('tile$index'),
          width: gameTileWidth,
          height: gameTileHeight,
          child: Focus(focusNode: nodeFor(index), child: const SizedBox()),
        ),
      );

      return nodes;
    }

    Future<void> sendIntent(WidgetTester tester, Intent intent) async {
      final context = primaryFocus!.context!;

      final action = Actions.maybeFind(context, intent: intent);

      expect(action, isNotNull);

      Actions.of(context).invokeAction(action!, intent);

      await tester.pumpAndSettle();
    }

    List<int> visibleTiles(WidgetTester tester) => [
      for (var i = 0; i < 5; i++)
        if (find.byKey(ValueKey('tile$i')).evaluate().isNotEmpty) i,
    ];

    testWidgets('the next tab intent shows the next page', (tester) async {
      final nodes = await pumpPagedGrid(tester);

      nodes[0]!.requestFocus();
      await tester.pumpAndSettle();

      await sendIntent(tester, const NextTabIntent());

      expect(visibleTiles(tester), [2, 3]);
    });

    testWidgets('the previous tab intent shows the previous page', (
      tester,
    ) async {
      final nodes = await pumpPagedGrid(tester);

      nodes[0]!.requestFocus();
      await tester.pumpAndSettle();

      await sendIntent(tester, const NextTabIntent());
      await sendIntent(tester, const PreviousTabIntent());

      expect(visibleTiles(tester), [0, 1]);
    });

    testWidgets('focus moves to the first tile of the new page', (
      tester,
    ) async {
      final nodes = await pumpPagedGrid(tester);

      nodes[0]!.requestFocus();
      await tester.pumpAndSettle();

      await sendIntent(tester, const NextTabIntent());

      expect(primaryFocus?.debugLabel, 'tile2');
    });

    testWidgets('the next tab intent does nothing on the last page', (
      tester,
    ) async {
      final nodes = await pumpPagedGrid(tester);

      nodes[0]!.requestFocus();
      await tester.pumpAndSettle();

      await sendIntent(tester, const NextTabIntent());
      await sendIntent(tester, const NextTabIntent());
      await sendIntent(tester, const NextTabIntent());

      expect(visibleTiles(tester), [4]);
      expect(primaryFocus?.debugLabel, 'tile4');
    });

    testWidgets('a controller passed in pages the grid', (tester) async {
      final controller = PaginatedGridController();

      addTearDown(controller.dispose);

      await pumpPagedGrid(tester, controller: controller);

      controller.nextPage();
      await tester.pumpAndSettle();

      expect(visibleTiles(tester), [2, 3]);
    });

    testWidgets('a controller page change moves focus to the first tile', (
      tester,
    ) async {
      final controller = PaginatedGridController();

      addTearDown(controller.dispose);

      final nodes = await pumpPagedGrid(tester, controller: controller);

      nodes[0]!.requestFocus();
      await tester.pumpAndSettle();

      controller.nextPage();
      await tester.pumpAndSettle();

      expect(primaryFocus?.debugLabel, 'tile2');
    });

    testWidgets('the previous tab intent does nothing on the first page', (
      tester,
    ) async {
      final nodes = await pumpPagedGrid(tester);

      nodes[1]!.requestFocus();
      await tester.pumpAndSettle();

      await sendIntent(tester, const PreviousTabIntent());

      expect(visibleTiles(tester), [0, 1]);
      expect(primaryFocus?.debugLabel, 'tile1');
    });
  });
}
