import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_tile.dart';

import '../../helpers/focus.dart';

void main() {
  testWidgets('a tile with no onTap is still a focus stop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Focus(child: SettingsTile(child: SizedBox())),
        ),
      ),
    );
    await tester.pump();

    focusInto(tester, find.byType(SettingsTile));
    await tester.pump();

    expect(focusInside(tester, find.byType(SettingsTile)), isTrue);

    // confirm on a verb-less tile is a harmless no-op
    Actions.invoke(
      FocusManager.instance.primaryFocus!.context!,
      const ActivateIntent(),
    );
    await tester.pump();
  });

  testWidgets('a tile with onTap still activates on confirm', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Focus(
            child: SettingsTile(
              onTap: () => tapped = true,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    focusInto(tester, find.byType(SettingsTile));
    await tester.pump();

    final context = FocusManager.instance.primaryFocus!.context!;

    Actions.invoke(context, const ActivateIntent());

    expect(tapped, isTrue);
  });

  testWidgets(
    'focusing a tile focuses its InkWell so it paints the highlight',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Focus(
              child: SettingsTile(onTap: () {}, child: const SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();

      focusInto(tester, find.byType(SettingsTile));
      await tester.pump();

      expect(focusInside(tester, find.byType(InkWell)), isTrue);
    },
  );
}
