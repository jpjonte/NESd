import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/splash/splash.dart';

void main() {
  test('dismissSplash is a no-op off the web', () {
    expect(dismissSplash, returnsNormally);
  });
}
