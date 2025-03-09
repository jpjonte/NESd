import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/about/about_dialog.dart';
import 'package:nesd/ui/emulator/main_menu.dart';

class MainMenuRobot {
  MainMenuRobot(this.tester);

  final WidgetTester tester;

  void expectMainMenuFound() {
    expect(find.byType(MainMenu), findsOneWidget);
  }

  void expectAboutDialogFound() {
    expect(find.byType(AboutDialog), findsOneWidget);
  }

  Future<void> openAboutDialog() async {
    final aboutButton = find.byKey(MainMenu.aboutKey);

    expect(aboutButton, findsOneWidget);

    await tester.tap(aboutButton);

    await tester.pumpAndSettle();
  }
}
