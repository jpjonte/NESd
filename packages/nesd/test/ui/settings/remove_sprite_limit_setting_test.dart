import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('Remove sprite limit defaults to off', () {
    expect(Settings().removeSpriteLimit, isFalse);
    expect(Settings.fromJson({}).removeSpriteLimit, isFalse);
  });

  test('Remove sprite limit setting survives a JSON round trip', () {
    final settings = Settings(removeSpriteLimit: true);

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.removeSpriteLimit, isTrue);
  });
}
