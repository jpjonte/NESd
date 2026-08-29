import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('overscan round-trips through JSON', () {
    final settings = Settings(
      overscan: const Overscan(top: 1, bottom: 2, left: 3, right: 4),
    );

    final restored = Settings.fromJson(settings.toJson());

    expect(
      restored.overscan,
      const Overscan(top: 1, bottom: 2, left: 3, right: 4),
    );
  });

  test('overscan defaults to 8 top and bottom for missing settings keys', () {
    expect(Settings.fromJson(const {}).overscan, const Overscan());
  });

  test('overscan tolerates a null stored value', () {
    expect(
      Settings.fromJson(const {'overscan': null}).overscan,
      const Overscan(),
    );
  });
}
