import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/screenshot/screenshot_mode.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('screenshots default to the raw frame', () {
    expect(Settings().screenshotMode, ScreenshotMode.raw);
    expect(Settings.fromJson({}).screenshotMode, ScreenshotMode.raw);
  });

  test('the screenshot mode survives a JSON round trip', () {
    final settings = Settings(screenshotMode: ScreenshotMode.displayed);

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.screenshotMode, ScreenshotMode.displayed);
  });
}
