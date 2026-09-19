import 'dart:ui';

import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/input_device.dart';
import 'package:nesd/nes/ppu/ppu.dart';

const _dotsPerScanline = 341;

const _lightDecayDots = 26 * _dotsPerScanline;

const _sensorRadius = 2;

const _brightnessThreshold = 64;

const _minimumTriggerFrames = 6;

const _noPull = -1;

class Zapper implements InputDevice {
  Zapper({required this.bus});

  final Bus bus;

  bool get trigger => _held;

  set trigger(bool value) {
    _held = value;

    if (value) {
      _pulledAtFrame = bus.ppu.frames;
    }
  }

  bool _held = false;

  int _pulledAtFrame = _noPull;

  Offset? position = Offset.zero;

  @override
  int read(int address, {bool disableSideEffects = false}) {
    final lightValue = _calculateLightValue();
    final trigger = _held || _withinMinimumHold() ? 1 : 0;

    return (trigger << 4) | (lightValue << 3);
  }

  bool _withinMinimumHold() {
    if (_pulledAtFrame == _noPull) {
      return false;
    }

    final elapsed = bus.ppu.frames - _pulledAtFrame;

    return elapsed >= 0 && elapsed < _minimumTriggerFrames;
  }

  @override
  void write(int address, int value) {}

  @override
  void revertWrite() {}

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

    if (delta <= 0) {
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
