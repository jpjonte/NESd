import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/settings_section_header.dart';
import 'package:nesd/ui/theme/light.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: nesdThemeLight,
    home: Scaffold(body: child),
  );

  testWidgets('shows its title', (tester) async {
    await tester.pumpWidget(wrap(const SettingsSectionHeader(title: 'Mixer')));

    expect(find.text('Mixer'), findsOneWidget);
  });

  testWidgets('adds no focus stop for gamepad traversal', (tester) async {
    await tester.pumpWidget(wrap(const SettingsSectionHeader(title: 'Mixer')));

    expect(
      find.descendant(
        of: find.byType(SettingsSectionHeader),
        matching: find.byType(Focus),
      ),
      findsNothing,
    );
  });
}
