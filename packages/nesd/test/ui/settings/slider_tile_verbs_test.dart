import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

void main() {
  Future<Robot> focusVolume(WidgetTester tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.audio);

    r.settings.volume = 0.5;
    await tester.pumpAndSettle();

    focusInto(tester, find.byType(VolumeSlider));
    await tester.pumpAndSettle();

    return r;
  }

  testWidgets('left and right step the volume on the gamepad', (tester) async {
    final r = await focusVolume(tester);

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();

    expect(r.settings.volume, closeTo(0.45, 1e-9));
    expect(focusInside(tester, find.byType(VolumeSlider)), isTrue);

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();
    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.settings.volume, closeTo(0.55, 1e-9));
  });

  testWidgets('arrow keys step the volume on the keyboard', (tester) async {
    final r = await focusVolume(tester);

    await r.pressKey(LogicalKeyboardKey.arrowRight);

    expect(r.settings.volume, closeTo(0.55, 1e-9));
    expect(focusInside(tester, find.byType(VolumeSlider)), isTrue);
  });

  testWidgets('secondary action resets the slider', (tester) async {
    final r = await focusVolume(tester);

    r.settings.volume = 0.8;
    await tester.pumpAndSettle();

    r.sendInputAction(secondaryAction);
    await tester.pumpAndSettle();

    expect(r.settings.volume, 0.5);
  });

  testWidgets('the value never leaves the slider range', (tester) async {
    final r = await focusVolume(tester);

    r.settings.volume = 1.0;
    await tester.pumpAndSettle();

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.settings.volume, 1.0);
  });
}
