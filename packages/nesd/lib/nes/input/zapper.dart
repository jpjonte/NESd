import 'dart:ui';

import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/input_device.dart';

class Zapper implements InputDevice {
  Zapper({required this.bus});

  final Bus bus;

  bool get trigger => _trigger == 1;

  set trigger(bool value) => _trigger = value ? 1 : 0;

  int _trigger = 0;

  Offset? position = Offset.zero;

  @override
  int read(int address, {bool disableSideEffects = false}) {
    final lightValue = _calculateLightValue();

    return (_trigger << 4) | (lightValue << 3);
  }

  @override
  void write(int address, int value) {}

  int _calculateLightValue() {
    if (position case final position?) {
      final x = position.dx.floor();
      final y = position.dy.floor();

      final scanline = bus.ppu.scanline;
      final cycle = bus.ppu.cycle;

      // zapper must be behind the PPU scanline / cycle
      // otherwise we would be reading last frame's pixels
      if (scanline < y) {
        return 1;
      }

      if (scanline == y && cycle <= x) {
        return 1;
      }

      final brightness = bus.ppu.getPixelBrightness(x, y);

      if (brightness > 64) {
        return 0;
      }
    }

    return 1;
  }
}
