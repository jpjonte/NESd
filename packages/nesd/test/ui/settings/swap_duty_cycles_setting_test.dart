import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('swap duty cycles defaults to off', () {
    expect(Settings().swapDutyCycles, isFalse);
    expect(Settings.fromJson({}).swapDutyCycles, isFalse);
  });

  test('swap duty cycles setting survives a JSON round trip', () {
    final settings = Settings(swapDutyCycles: true);

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.swapDutyCycles, isTrue);
  });
}
