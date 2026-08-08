import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/rom_tile.dart';

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
                height: 800,
                child: PaginatedGrid(
                  children: [for (var i = 0; i < tileCount; i++) _tile(i)],
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
}
