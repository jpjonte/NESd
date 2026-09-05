import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/display_geometry.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  DisplayGeometry geometry({
    required Size box,
    int visibleWidth = 256,
    int visibleHeight = 240,
    double pixelAspectRatio = 1,
    Scaling scaling = Scaling.autoSmooth,
    bool showTouchControls = false,
  }) {
    return calculateDisplayGeometry(
      constraints: BoxConstraints.tight(box),
      visibleWidth: visibleWidth,
      visibleHeight: visibleHeight,
      pixelAspectRatio: pixelAspectRatio,
      scaling: scaling,
      showTouchControls: showTouchControls,
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

  test('centres the frame in the box', () {
    final result = geometry(box: const Size(1000, 480));

    expect(result.topLeft, const Offset(244, 0));
  });

  test('anchors above centre in portrait with touch controls', () {
    final result = geometry(
      box: const Size(480, 1000),
      showTouchControls: true,
    );

    expect(result.scaledSize, const Size(480, 450));
    expect(result.topLeft, const Offset(0, 65));
  });

  test('keeps the frame centred in landscape even with touch controls', () {
    final result = geometry(
      box: const Size(1000, 480),
      showTouchControls: true,
    );

    expect(result.topLeft, const Offset(244, 0));
  });

  test('turns the pixel aspect ratio setting into a ratio', () {
    double ratio(PixelAspectRatio setting, {Region region = Region.ntsc}) =>
        calculatePixelAspectRatio(
          pixelAspectRatio: setting,
          customPixelAspectRatio: 1.5,
          region: region,
          constraints: BoxConstraints.tight(const Size(400, 200)),
        );

    expect(ratio(PixelAspectRatio.auto), 8 / 7);
    expect(ratio(PixelAspectRatio.auto, region: Region.pal), 11 / 8);
    expect(ratio(PixelAspectRatio.ntsc), 8 / 7);
    expect(ratio(PixelAspectRatio.pal), 11 / 8);
    expect(ratio(PixelAspectRatio.square), 1);
    expect(ratio(PixelAspectRatio.stretch), 2);
    expect(ratio(PixelAspectRatio.custom), 1.5);
  });
}
