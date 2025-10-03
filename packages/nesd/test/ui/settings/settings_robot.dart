import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/settings_screen.dart';

import '../base_robot.dart';
import 'controls/controls_settings_robot.dart';
import 'debug/debug_settings_robot.dart';

class SettingsScreenRobot extends BaseRobot {
  SettingsScreenRobot(super.tester)
    : debug = DebugSettingsRobot(tester),
      controls = ControlsSettingsRobot(tester);

  final ControlsSettingsRobot controls;
  final DebugSettingsRobot debug;

  void expectSettingsScreenFound() {
    expect(find.byType(SettingsScreen), findsOneWidget);
  }

  void expectTabHeadersFound() {
    expect(find.byKey(SettingsScreen.generalKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.graphicsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.audioKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.controlsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.debugKey), findsOneWidget);
  }

  void expectGeneralTabFound() {
    expect(find.byKey(SettingsScreen.generalKey), findsOneWidget);
  }

  void expectGraphicsTabFound() {
    expect(find.byKey(SettingsScreen.graphicsKey), findsOneWidget);
  }

  void expectAudioTabFound() {
    expect(find.byKey(SettingsScreen.audioKey), findsOneWidget);
  }

  void expectControlsTabFound() {
    expect(find.byKey(SettingsScreen.controlsKey), findsOneWidget);
  }

  Future<void> tapGraphicsTab() async {
    await go(find.byKey(SettingsScreen.graphicsKey));
  }

  Future<void> tapAudioTab() async {
    await go(find.byKey(SettingsScreen.audioKey));
  }

  Future<void> tapControlsTab() async {
    await go(find.byKey(SettingsScreen.controlsKey));
  }

  Future<void> tapDebugTab() async {
    await go(find.byKey(SettingsScreen.debugKey));
  }
}
