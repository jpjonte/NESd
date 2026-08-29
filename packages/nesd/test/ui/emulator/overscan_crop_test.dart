import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/overscan_crop.dart';

void main() {
  const childKey = Key('child');

  Future<void> pumpCrop(
    WidgetTester tester, {
    required Overscan overscan,
    Size box = const Size(496, 448),
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: box.width,
            height: box.height,
            child: OverscanCrop(
              overscan: overscan,
              imageWidth: 256,
              imageHeight: 240,
              child: const SizedBox.expand(key: childKey),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('scales the child so the visible area fills the box', (
    tester,
  ) async {
    await pumpCrop(
      tester,
      overscan: const Overscan(top: 12, bottom: 4, left: 4, right: 4),
    );

    expect(
      tester.getRect(find.byKey(childKey)),
      const Rect.fromLTWH(-8, -24, 512, 480),
    );
  });

  testWidgets('shifts the child down when only the top is cropped', (
    tester,
  ) async {
    await pumpCrop(
      tester,
      overscan: const Overscan(top: 12, bottom: 0),
      box: const Size(256, 228),
    );

    expect(
      tester.getRect(find.byKey(childKey)),
      const Rect.fromLTWH(0, -12, 256, 240),
    );
  });

  testWidgets('clips the child to the box', (tester) async {
    await pumpCrop(tester, overscan: const Overscan());

    expect(find.byType(ClipRect), findsOneWidget);
  });

  testWidgets('leaves the child untouched when nothing is cropped', (
    tester,
  ) async {
    await pumpCrop(tester, overscan: Overscan.none);

    expect(find.byType(ClipRect), findsNothing);
    expect(
      tester.getRect(find.byKey(childKey)),
      const Rect.fromLTWH(0, 0, 496, 448),
    );
  });
}
