import 'dart:ui';

import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/input_device.dart';
import 'package:nesd/nes/ppu/ppu.dart';

const _dotsPerScanline = 341;

const _lightDecayDots = 26 * _dotsPerScanline;

const _sensorRadius = 2;

const _brightnessThreshold = 64;

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
      final centerX = position.dx.floor();
      final centerY = position.dy.floor();

      for (var y = centerY - _sensorRadius; y <= centerY + _sensorRadius; y++) {
        for (
          var x = centerX - _sensorRadius;
          x <= centerX + _sensorRadius;
          x++
        ) {
          if (_pixelLit(x, y)) {
            return 0;
          }
        }
      }
    }

    return 1;
  }

  bool _pixelLit(int x, int y) {
    if (x < 0 || x >= 256 || y < 0 || y >= 240) {
      return false;
    }

    final ppu = bus.ppu;

    final beamDot = ppu.scanline * _dotsPerScanline + ppu.cycle;
    final pixelDot = y * _dotsPerScanline + x + 1;

    var delta = beamDot - pixelDot;

    var previousFrame = ppu.scanline >= vblankScanline;

    if (delta < 0) {
      delta += (ppu.preRenderScanline + 1) * _dotsPerScanline;
      previousFrame = true;
    }

    if (delta > _lightDecayDots) {
      return false;
    }

    final brightness = ppu.getPixelBrightness(
      x,
      y,
      previousFrame: previousFrame,
    );

    return brightness > _brightnessThreshold;
  }
}
