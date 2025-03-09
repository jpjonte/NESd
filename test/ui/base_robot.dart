import 'package:flutter_test/flutter_test.dart';

abstract class BaseRobot {
  BaseRobot(this.tester);

  final WidgetTester tester;

  Future<void> go(Finder finder) async {
    await expectAndTap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> expectAndTap(Finder finder) async {
    expect(finder, findsOneWidget);
    await tester.tap(finder);
  }
}
