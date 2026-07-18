import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/zapper.dart';
import 'package:nesd/nes/ppu/ppu.dart';

class MockBus extends Mock implements Bus {}

class MockPPU extends Mock implements PPU {}

void main() {
  group('Zapper', () {
    late MockBus bus;
    late MockPPU ppu;
    late Zapper zapper;

    setUp(() {
      bus = MockBus();
      ppu = MockPPU();

      when(() => bus.ppu).thenReturn(ppu);
      when(() => ppu.preRenderScanline).thenReturn(261);

      zapper = Zapper(bus: bus);
    });

    void stubBeam({required int scanline, required int cycle}) {
      when(() => ppu.scanline).thenReturn(scanline);
      when(() => ppu.cycle).thenReturn(cycle);
    }

    void stubBrightness(int value, {required bool previousFrame}) {
      when(
        () =>
            ppu.getPixelBrightness(any(), any(), previousFrame: previousFrame),
      ).thenReturn(value);
    }

    void stubBrightPixel(int brightX, int brightY) {
      when(
        () => ppu.getPixelBrightness(
          any(),
          any(),
          previousFrame: any(named: 'previousFrame'),
        ),
      ).thenAnswer((invocation) {
        final x = invocation.positionalArguments[0] as int;
        final y = invocation.positionalArguments[1] as int;
        final previousFrame = invocation.namedArguments[#previousFrame] as bool;

        return x == brightX && y == brightY && !previousFrame ? 765 : 0;
      });
    }

    int lightBit(int value) => (value >> 3) & 1;

    int triggerBit(int value) => (value >> 4) & 1;

    test('sets trigger bit while trigger is pulled', () {
      stubBeam(scanline: 0, cycle: 0);
      stubBrightness(0, previousFrame: false);
      stubBrightness(0, previousFrame: true);

      zapper
        ..position = null
        ..trigger = true;

      expect(triggerBit(zapper.read(0)), 1);

      zapper.trigger = false;

      expect(triggerBit(zapper.read(0)), 0);
    });

    test('reports no light without a position', () {
      stubBeam(scanline: 100, cycle: 0);
      stubBrightness(765, previousFrame: false);
      stubBrightness(765, previousFrame: true);

      zapper.position = null;

      expect(lightBit(zapper.read(0)), 1);
    });

    test('detects light right after the beam passes a bright pixel', () {
      stubBeam(scanline: 101, cycle: 0);
      stubBrightPixel(100, 100);

      zapper.position = const Offset(100, 100);

      expect(lightBit(zapper.read(0)), 0);
    });

    test('reports no light before the beam reaches the pixel', () {
      stubBeam(scanline: 30, cycle: 0);
      stubBrightness(765, previousFrame: false);
      stubBrightness(765, previousFrame: true);

      zapper.position = const Offset(128, 200);

      expect(lightBit(zapper.read(0)), 1);
    });

    test('light decays about 26 scanlines after the beam passes', () {
      // Beam is 30 scanlines beyond the aimed pixel; even a fully bright
      // screen must read dark because the photodiode pulse has ended.
      stubBeam(scanline: 130, cycle: 0);
      stubBrightness(765, previousFrame: false);
      stubBrightness(765, previousFrame: true);

      zapper.position = const Offset(100, 100);

      expect(lightBit(zapper.read(0)), 1);
    });

    test('reads the completed frame during vblank', () {
      // At scanline 250 the frame buffer has been swapped: this frame's
      // pixels live in the previous buffer, and the write buffer holds
      // stale data from an older frame.
      stubBeam(scanline: 250, cycle: 100);
      stubBrightness(765, previousFrame: true);
      stubBrightness(0, previousFrame: false);

      zapper.position = const Offset(128, 230);

      expect(lightBit(zapper.read(0)), 0);
    });

    test('ignores the stale write buffer during vblank', () {
      stubBeam(scanline: 250, cycle: 100);
      stubBrightness(0, previousFrame: true);
      stubBrightness(765, previousFrame: false);

      zapper.position = const Offset(128, 230);

      expect(lightBit(zapper.read(0)), 1);
    });

    test('bottom rows stay lit into the next frame', () {
      // Scanline 2 of the new frame: the beam passed the bottom of the
      // previous frame ~25 scanlines ago, still within the decay window.
      stubBeam(scanline: 2, cycle: 0);
      stubBrightness(765, previousFrame: true);
      stubBrightness(0, previousFrame: false);

      zapper.position = const Offset(128, 239);

      expect(lightBit(zapper.read(0)), 0);
    });

    test('detects light within a small radius around the position', () {
      stubBeam(scanline: 101, cycle: 0);
      stubBrightPixel(102, 100);

      zapper.position = const Offset(100, 100);

      expect(lightBit(zapper.read(0)), 0);
    });

    test('reports no light for positions outside the frame', () {
      stubBeam(scanline: 250, cycle: 0);
      stubBrightness(765, previousFrame: false);
      stubBrightness(765, previousFrame: true);

      zapper.position = const Offset(300, 100);

      expect(lightBit(zapper.read(0)), 1);
    });
  });
}
