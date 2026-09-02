import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('a stored gain outside the usable range is clamped on load', () {
    final settings = Settings.fromJson(const {
      'mixer': {'triangle': -1.2, 'noise': 8.0},
    });

    expect(settings.mixer.triangle, 0.0);
    expect(settings.mixer.noise, 1.0);
  });

  test('the controller clamps what it stores, like volume does', () {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    addTearDown(container.dispose);

    final controller = container.read(settingsControllerProvider.notifier)
      ..mixer = const MixerSettings(pulse1: -1.2, dmc: 4);

    expect(controller.mixer.pulse1, 0.0);
    expect(controller.mixer.dmc, 1.0);
  });
}
