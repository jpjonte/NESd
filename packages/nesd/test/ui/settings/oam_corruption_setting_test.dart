import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('OAM corruption defaults to on', () {
    expect(Settings().oamCorruption, isTrue);
    expect(Settings.fromJson({}).oamCorruption, isTrue);
  });

  test('OAM corruption setting survives a JSON round trip', () {
    final settings = Settings(oamCorruption: false);

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.oamCorruption, isFalse);
  });
}
