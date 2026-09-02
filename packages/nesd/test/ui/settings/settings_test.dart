import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('fastForwardSpeed round-trips through JSON', () {
    final settings = Settings(fastForwardSpeed: FastForwardSpeed.x3);

    final restored = Settings.fromJson(settings.toJson());

    expect(restored.fastForwardSpeed, FastForwardSpeed.x3);
  });

  test('fastForwardSpeed defaults to 2x for missing settings keys', () {
    expect(Settings.fromJson(const {}).fastForwardSpeed, FastForwardSpeed.x2);
  });

  test('turboSpeed round-trips through JSON', () {
    final settings = Settings(turboSpeed: TurboSpeed.x3);

    final restored = Settings.fromJson(settings.toJson());

    expect(restored.turboSpeed, TurboSpeed.x3);
  });

  test('turboSpeed defaults to the fastest pulse for missing keys', () {
    expect(Settings.fromJson(const {}).turboSpeed, TurboSpeed.x1);
  });

  test('videoFilters round-trip through JSON', () {
    final settings = Settings(videoFilters: [VideoFilter.xbr, VideoFilter.crt]);

    final restored = Settings.fromJson(settings.toJson());

    expect(restored.videoFilters, [VideoFilter.xbr, VideoFilter.crt]);
  });
}
