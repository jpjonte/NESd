import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';

void main() {
  DisplayGeometry geometry({
    required Size box,
    int visibleWidth = 256,
    int visibleHeight = 240,
    double pixelAspectRatio = 1,
    Scaling scaling = Scaling.autoSmooth,
  }) {
    return calculateDisplayGeometry(
      constraints: BoxConstraints.tight(box),
      visibleWidth: visibleWidth,
      visibleHeight: visibleHeight,
      pixelAspectRatio: pixelAspectRatio,
      scaling: scaling,
    );
  }

  test('fills the box when the aspect ratios match', () {
    final result = geometry(box: const Size(512, 480));

    expect(result.scale, 2);
    expect(result.scaledSize, const Size(512, 480));
  });

  test('sizes to the visible area rather than the whole frame', () {
    final result = geometry(box: const Size(512, 480), visibleHeight: 224);

    expect(result.scale, 2);
    expect(result.scaledSize, const Size(512, 448));
  });

  test('stretches the width by the pixel aspect ratio', () {
    final result = geometry(
      box: const Size(1000, 224),
      visibleHeight: 224,
      pixelAspectRatio: 8 / 7,
    );

    // 256 * 8/7 rounds to 293.
    expect(result.scaledSize.width, closeTo(293, 0.001));
    expect(result.scaledSize.height, closeTo(224, 0.001));
  });

  test('integer scaling picks the largest whole multiple that fits', () {
    final result = geometry(
      box: const Size(1000, 900),
      visibleHeight: 224,
      scaling: Scaling.autoInteger,
    );

    expect(result.scale, 3);
    expect(result.scaledSize, const Size(768, 672));
  });

  test('a fixed scale is capped so the visible area still fits', () {
    final result = geometry(
      box: const Size(512, 448),
      visibleHeight: 224,
      scaling: Scaling.x4,
    );

    expect(result.scale, 2);
  });
}
