import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
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
}
