import 'package:flutter/foundation.dart';

@immutable
class PulseDebugState {
  const PulseDebugState({
    required this.enabled,
    required this.duty,
    required this.volume,
    required this.timerPeriod,
  });

  final bool enabled;

  /// Duty selector 0-3 (12.5%, 25%, 50%, 75%).
  final int duty;

  /// Effective volume 0-15: the constant volume or the envelope's
  /// current decay level.
  final int volume;

  final int timerPeriod;
}

@immutable
class TriangleDebugState {
  const TriangleDebugState({
    required this.enabled,
    required this.timerPeriod,
    required this.linearCounter,
    required this.lengthCounter,
  });

  final bool enabled;
  final int timerPeriod;
  final int linearCounter;
  final int lengthCounter;
}

@immutable
class NoiseDebugState {
  const NoiseDebugState({
    required this.enabled,
    required this.volume,
    required this.mode,
    required this.timerPeriod,
  });

  final bool enabled;

  /// Effective volume 0-15.
  final int volume;

  /// LFSR mode: true = short (93-step), false = long (32767-step).
  final bool mode;

  final int timerPeriod;
}

@immutable
class DmcDebugState {
  const DmcDebugState({
    required this.enabled,
    required this.level,
    required this.rate,
    required this.bytesRemaining,
  });

  final bool enabled;

  /// Current DAC level 0-127.
  final int level;

  final int rate;
  final int bytesRemaining;
}
