import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';

void main() {
  test('every channel defaults to unity gain', () {
    const settings = MixerSettings();

    expect(settings.pulse1, 1.0);
    expect(settings.pulse2, 1.0);
    expect(settings.triangle, 1.0);
    expect(settings.noise, 1.0);
    expect(settings.dmc, 1.0);
    expect(settings.mmc5, 1.0);
    expect(settings.namco163, 1.0);
  });

  test('round-trips through JSON', () {
    const settings = MixerSettings(
      pulse1: 0.0,
      pulse2: 0.25,
      triangle: 0.5,
      noise: 0.75,
      dmc: 0.875,
      mmc5: 0.125,
      namco163: 0.625,
    );

    expect(MixerSettings.fromJson(settings.toJson()), settings);
  });

  test('clamped pulls every gain into the usable range', () {
    const settings = MixerSettings(
      pulse1: -1.2,
      pulse2: 2,
      triangle: -0.0001,
      noise: 1.5,
      dmc: double.nan,
      mmc5: double.infinity,
      namco163: double.negativeInfinity,
    );

    final clamped = settings.clamped();

    expect(clamped.pulse1, 0.0);
    expect(clamped.pulse2, 1.0);
    expect(clamped.triangle, 0.0);
    expect(clamped.noise, 1.0);
    expect(clamped.dmc, isNot(isNaN));
    expect(clamped.mmc5, 1.0);
    expect(clamped.namco163, 0.0);
  });

  test('clamped leaves usable gains untouched', () {
    const settings = MixerSettings(pulse1: 0, pulse2: 0.5, triangle: 0.25);

    expect(settings.clamped(), settings);
  });

  test('fills in unity gain for keys missing from stored settings', () {
    final settings = MixerSettings.fromJson(const {'pulse1': 0.5});

    expect(settings.pulse1, 0.5);
    expect(settings.pulse2, 1.0);
    expect(settings.namco163, 1.0);
  });
}
