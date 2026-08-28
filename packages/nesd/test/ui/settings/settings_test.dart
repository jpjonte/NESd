import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
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
}
