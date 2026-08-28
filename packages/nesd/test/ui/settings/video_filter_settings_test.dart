import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  SettingsController load(String raw) {
    when(() => prefs.getString(any())).thenReturn(raw);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    addTearDown(container.dispose);

    return container.read(settingsControllerProvider.notifier);
  }

  test('video filter settings survive a JSON round trip', () {
    final settings = Settings(
      videoFilter: VideoFilter.crt,
      crtFilter: const CrtFilterSettings(
        scanlineIntensity: 0.5,
        maskStrength: 0.1,
        curvature: 0.2,
      ),
    );

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.videoFilter, VideoFilter.crt);
    expect(decoded.crtFilter.scanlineIntensity, 0.5);
    expect(decoded.crtFilter.maskStrength, 0.1);
    expect(decoded.crtFilter.curvature, 0.2);
  });

  test('settings JSON without filter keys falls back to defaults', () {
    final decoded = Settings.fromJson({});

    expect(decoded.videoFilter, VideoFilter.none);
    expect(decoded.crtFilter, const CrtFilterSettings());
    expect(decoded.crtFilter.scanlineIntensity, 0.35);
    expect(decoded.crtFilter.maskStrength, 0.25);
    expect(decoded.crtFilter.curvature, 0.0);
  });

  test('crt uniform order matches the definition order', () {
    const crt = CrtFilterSettings(
      scanlineIntensity: 0.1,
      maskStrength: 0.2,
      curvature: 0.03,
    );

    expect(videoFilterUniforms(VideoFilter.crt, crt), [0.1, 0.2, 0.03]);
    expect(videoFilterUniforms(VideoFilter.smooth, crt), isEmpty);
    expect(videoFilterUniforms(VideoFilter.none, crt), isEmpty);
  });

  test('normalizeVideoFilters enforces canonical order and drops '
      'duplicates and none', () {
    expect(normalizeVideoFilters([VideoFilter.crt, VideoFilter.smooth]), [
      VideoFilter.smooth,
      VideoFilter.crt,
    ]);
    expect(
      normalizeVideoFilters([
        VideoFilter.crt,
        VideoFilter.crt,
        VideoFilter.none,
      ]),
      [VideoFilter.crt],
    );
    expect(normalizeVideoFilters([]), isEmpty);
  });

  test('videoFilters survives a JSON round trip', () {
    final settings = Settings(
      videoFilters: const [VideoFilter.smooth, VideoFilter.crt],
    );

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.videoFilters, [VideoFilter.smooth, VideoFilter.crt]);
  });

  test('videoFilters defaults to empty', () {
    expect(Settings.fromJson({}).videoFilters, isEmpty);
  });

  test('toggleVideoFilter keeps canonical order regardless of toggle '
      'order', () {
    final controller = load('{}');

    // ignore: cascade_invocations
    controller
      ..toggleVideoFilter(VideoFilter.crt, enabled: true)
      ..toggleVideoFilter(VideoFilter.smooth, enabled: true);

    expect(controller.videoFilters, [VideoFilter.smooth, VideoFilter.crt]);

    controller.toggleVideoFilter(VideoFilter.smooth, enabled: false);

    expect(controller.videoFilters, [VideoFilter.crt]);
  });
}
