import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/controls/turbo_speed_selector.dart';
import 'package:nesd/ui/settings/general/fast_forward_speed_selector.dart';
import 'package:nesd/ui/settings/general/region_selector.dart';
import 'package:nesd/ui/settings/general/theme_mode_selector.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../robot.dart';

const _phone = Size(411, 891);

void main() {
  for (final (category, selectors) in [
    (
      SettingsCategory.general,
      [RegionSelector, FastForwardSpeedSelector, ThemeModeSelector],
    ),
    (SettingsCategory.controls, [TurboSpeedSelector]),
  ]) {
    testWidgets('segment labels in ${category.title} fit on one line on a '
        'phone', (tester) async {
      final r = Robot(tester);

      await r.pumpApp(logicalSize: _phone, devicePixelRatio: 3.5);
      await r.mainMenu.tapSettingsButton();
      await r.settingsScreen.openCategory(category);

      for (final selector in selectors) {
        final finder = find.byType(selector);

        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();

        final labels = find.descendant(
          of: find.descendant(
            of: finder,
            matching: find.byWidgetPredicate((w) => w is SegmentedButton),
          ),
          matching: find.byType(Text),
        );

        expect(labels, findsWidgets);

        for (final label in labels.evaluate()) {
          final paragraph = label.findRenderObject()! as RenderParagraph;
          final text = (label.widget as Text).data;

          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.01),
            reason: '$selector label "$text" wraps',
          );
        }
      }
    });
  }
}
