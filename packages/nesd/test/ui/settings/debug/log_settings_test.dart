import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/router/router.dart';

import '../../robot.dart';

void main() {
  testWidgets('the log level defaults to info and persists a change', (
    tester,
  ) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    expect(robot.settings.logLevel, LogLevel.info);

    robot.settings.logLevel = LogLevel.debug;

    await tester.pumpAndSettle();

    expect(robot.settings.logLevel, LogLevel.debug);
  });

  testWidgets('changing the level updates the ambient logger', (tester) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.settings.logLevel = LogLevel.error;

    await tester.pumpAndSettle();

    expect(NesdLog.instance.minimumLevel, LogLevel.error);
  });

  testWidgets('the debug tab shows the level dropdown', (tester) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const SettingsRoute());

    await tester.pumpAndSettle();

    await robot.settingsScreen.tapDebugTab();

    robot.settingsScreen.debug.expectLogLevelDropdownFound();
  });
}
