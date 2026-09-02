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

  test('fills in unity gain for keys missing from stored settings', () {
    final settings = MixerSettings.fromJson(const {'pulse1': 0.5});

    expect(settings.pulse1, 0.5);
    expect(settings.pulse2, 1.0);
    expect(settings.namco163, 1.0);
  });
}
