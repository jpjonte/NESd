import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('low pass filter defaults to off', () {
    expect(Settings().lowPassFilter, isFalse);
    expect(Settings.fromJson({}).lowPassFilter, isFalse);
  });

  test('low pass filter setting survives a JSON round trip', () {
    final settings = Settings(lowPassFilter: true);

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.lowPassFilter, isTrue);
  });
}
