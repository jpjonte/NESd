import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('the mixer defaults to unity gain on every channel', () {
    expect(Settings().mixer, const MixerSettings());
    expect(Settings.fromJson(const {}).mixer, const MixerSettings());
  });

  test('the mixer round-trips through JSON', () {
    final settings = Settings(
      mixer: const MixerSettings(pulse1: 0.25, dmc: 0, namco163: 0.5),
    );

    final restored = Settings.fromJson(settings.toJson());

    expect(
      restored.mixer,
      const MixerSettings(pulse1: 0.25, dmc: 0, namco163: 0.5),
    );
  });

  test('the mixer tolerates a null stored value', () {
    expect(
      Settings.fromJson(const {'mixer': null}).mixer,
      const MixerSettings(),
    );
  });
}
