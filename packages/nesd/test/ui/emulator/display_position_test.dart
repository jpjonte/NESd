import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display_position.dart';

void main() {
  group('nesPositionFromDisplay', () {
    const par = 8 / 7;

    Offset? map(Offset displayPosition, {double scale = 2}) {
      return nesPositionFromDisplay(
        displayPosition: displayPosition,
        scale: scale,
        pixelAspectRatio: par,
        imageWidth: 256,
        imageHeight: 240,
      );
    }

    test('maps the display center to the framebuffer center', () {
      final position = map(const Offset(128 * par * 2, 120 * 2));

      expect(position, isNotNull);
      expect(position!.dx, closeTo(128, 0.001));
      expect(position.dy, closeTo(120, 0.001));
    });

    test('maps the right edge inside the framebuffer', () {
      final position = map(const Offset(255 * par * 2, 100));

      expect(position, isNotNull);
      expect(position!.dx, closeTo(255, 0.001));
    });

    test('returns null outside the frame', () {
      expect(map(const Offset(256 * par * 2, 100)), isNull);
      expect(map(const Offset(-1, 100)), isNull);
      expect(map(const Offset(100, 240 * 2)), isNull);
    });

    test('is the identity mapping for square pixels at scale 1', () {
      final position = nesPositionFromDisplay(
        displayPosition: const Offset(100, 50),
        scale: 1,
        pixelAspectRatio: 1,
        imageWidth: 256,
        imageHeight: 240,
      );

      expect(position, equals(const Offset(100, 50)));
    });
  });

  group('displayPositionFromNes', () {
    test('round-trips with nesPositionFromDisplay', () {
      const par = 8 / 7;
      const original = Offset(100, 50);

      final display = displayPositionFromNes(
        position: original,
        scale: 3,
        pixelAspectRatio: par,
      );

      final roundTripped = nesPositionFromDisplay(
        displayPosition: display,
        scale: 3,
        pixelAspectRatio: par,
        imageWidth: 256,
        imageHeight: 240,
      );

      expect(roundTripped, isNotNull);
      expect(roundTripped!.dx, closeTo(original.dx, 0.001));
      expect(roundTripped.dy, closeTo(original.dy, 0.001));
    });

    test('stretches x by the pixel aspect ratio', () {
      final display = displayPositionFromNes(
        position: const Offset(128, 120),
        scale: 2,
        pixelAspectRatio: 8 / 7,
      );

      expect(display.dx, closeTo(128 * (8 / 7) * 2, 0.001));
      expect(display.dy, closeTo(240, 0.001));
    });
  });
}
