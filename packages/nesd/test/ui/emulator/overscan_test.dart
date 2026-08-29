import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/overscan.dart';

void main() {
  group('Overscan', () {
    test('crops 8 pixels top and bottom by default', () {
      const overscan = Overscan();

      expect(overscan.top, 8);
      expect(overscan.bottom, 8);
      expect(overscan.left, 0);
      expect(overscan.right, 0);
    });

    test('none crops nothing', () {
      expect(Overscan.none.visibleWidth(256), 256);
      expect(Overscan.none.visibleHeight(240), 240);
    });

    test('visibleWidth subtracts the horizontal crop', () {
      const overscan = Overscan(left: 4, right: 6);

      expect(overscan.visibleWidth(256), 246);
    });

    test('visibleHeight subtracts the vertical crop', () {
      const overscan = Overscan(top: 6, bottom: 10);

      expect(overscan.visibleHeight(240), 224);
    });

    test('visibleRect covers the uncropped area of the frame', () {
      const overscan = Overscan(top: 6, bottom: 10, left: 4, right: 2);

      expect(
        overscan.visibleRect(256, 240),
        const Rect.fromLTWH(4, 6, 250, 224),
      );
    });

    test('round-trips through json', () {
      const overscan = Overscan(top: 1, bottom: 2, left: 3, right: 4);

      expect(Overscan.fromJson(overscan.toJson()), overscan);
    });
  });
}
