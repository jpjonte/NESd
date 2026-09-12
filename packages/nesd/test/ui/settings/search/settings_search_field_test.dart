import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/search/settings_search_field.dart';
import 'package:nesd/ui/theme/light.dart';

import '../../../helpers/fonts.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.onDismiss, required this.onSubmitted});

  final VoidCallback onDismiss;
  final VoidCallback onSubmitted;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String value = '';

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            widget.onDismiss();

            return null;
          },
        ),
      },
      child: SettingsSearchField(
        value: value,
        onChanged: (next) => setState(() => value = next),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

void main() {
  late int dismissed;
  late int submitted;

  Future<_HarnessState> pumpField(WidgetTester tester) async {
    dismissed = 0;
    submitted = 0;

    await loadAppFonts();

    await tester.pumpWidget(
      MaterialApp(
        theme: nesdThemeLight,
        home: Scaffold(
          body: _Harness(
            onDismiss: () => dismissed++,
            onSubmitted: () => submitted++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.state(find.byType(_Harness));
  }

  final field = find.byKey(SettingsSearchField.fieldKey);
  final clear = find.byKey(SettingsSearchField.clearKey);

  testWidgets('typing reports the value and shows the clear button', (
    tester,
  ) async {
    final harness = await pumpField(tester);

    expect(find.text('Search settings'), findsOneWidget);
    expect(clear, findsNothing);

    await tester.enterText(field, 'start');
    await tester.pumpAndSettle();

    expect(harness.value, 'start');
    expect(clear, findsOneWidget);
  });

  testWidgets('the focused field paints a primary background', (tester) async {
    await pumpField(tester);

    await tester.tap(field);
    await tester.pumpAndSettle();

    final focusedBox = tester.widget<ColoredBox>(
      find.ancestor(of: field, matching: find.byType(ColoredBox)).first,
    );

    expect(focusedBox.color, nesdThemeLight.colorScheme.primary);
    expect(
      tester.widget<TextField>(field).decoration?.hintStyle?.color,
      Colors.grey[300],
    );

    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final unfocusedBox = tester.widget<ColoredBox>(
      find.ancestor(of: field, matching: find.byType(ColoredBox)).first,
    );

    expect(unfocusedBox.color, nesdThemeLight.colorScheme.surface);
    expect(
      tester.widget<TextField>(field).decoration?.hintStyle?.color,
      isNull,
    );
  });

  testWidgets('the clear button empties the field', (tester) async {
    final harness = await pumpField(tester);

    await tester.enterText(field, 'start');
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();

    expect(harness.value, '');
    expect(find.text('start'), findsNothing);
    expect(clear, findsNothing);
  });

  testWidgets('dismiss clears a non-empty query without leaving', (
    tester,
  ) async {
    final harness = await pumpField(tester);

    await tester.enterText(field, 'start');
    await tester.pumpAndSettle();

    Actions.invoke(tester.element(field), const DismissIntent());
    await tester.pumpAndSettle();

    expect(harness.value, '');
    expect(dismissed, 0);
    expect(
      tester.binding.focusManager.primaryFocus?.context,
      isNotNull,
      reason: 'clearing keeps focus in the field',
    );
  });

  testWidgets('dismiss on an empty query bubbles to the outer handler', (
    tester,
  ) async {
    await pumpField(tester);

    Actions.invoke(tester.element(field), const DismissIntent());
    await tester.pumpAndSettle();

    expect(dismissed, 1);
  });

  testWidgets('the Escape key reaches the field through the text editor', (
    tester,
  ) async {
    final harness = await pumpField(tester);

    await tester.enterText(field, 'start');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(harness.value, '');
    expect(dismissed, 0);
  });

  testWidgets('submitting the field reports onSubmitted', (tester) async {
    await pumpField(tester);

    await tester.enterText(field, 'start');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(submitted, 1);
  });
}
