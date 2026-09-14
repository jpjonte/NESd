import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/input_hint_resolver.dart';
import 'package:nesd/ui/emulator/input/input_method.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

RewindScrubState _state({int captureInterval = 1}) => RewindScrubState(
  open: true,
  cursorSequence: 60,
  oldestSequence: 0,
  newestSequence: 60,
  captureInterval: captureInterval,
  frameRate: 60,
  thumbnails: const [],
  thumbnailSequences: const [],
  settled: true,
);

final _defaultBindings = [...defaultBindings, ...defaultGamepadBindings];

Future<void> _pump(
  WidgetTester tester, {
  RewindScrubState? state,
  InputMethod method = InputMethod.keyboardMouse,
  Bindings? bindings,
  VoidCallback? onCommit,
  VoidCallback? onCancel,
}) async {
  final filmState = state ?? _state();

  final resolver = InputHintResolver(
    method: method,
    bindings: bindings ?? _defaultBindings,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [inputHintResolverProvider.overrideWith((_) => resolver)],
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RewindFilmstrip(
              state: filmState,
              secondsBack: (sequence) =>
                  (filmState.newestSequence - sequence) *
                  filmState.captureInterval /
                  filmState.frameRate,
              onScrubBy: (_) {},
              onCommit: onCommit ?? () {},
              onCancel: onCancel ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

double _chipHeight(WidgetTester tester, String label) => tester
    .getSize(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
    )
    .height;

void main() {
  testWidgets('names the arrow steps in seconds and frames', (tester) async {
    await _pump(tester);

    expect(find.text('Skip 1 second · hold to speed up'), findsOneWidget);
    expect(find.text('Step 1 frame'), findsOneWidget);
    expect(find.textContaining('Drag'), findsNothing);
  });

  testWidgets('shows the bound arrow keys as caps', (tester) async {
    await _pump(tester);

    expect(find.text('←'), findsOneWidget);
    expect(find.text('→'), findsOneWidget);
    expect(find.text('↑'), findsOneWidget);
    expect(find.text('↓'), findsOneWidget);
  });

  testWidgets('swaps the key hints for drag and tap hints on touch', (
    tester,
  ) async {
    await _pump(tester, method: InputMethod.touch);

    expect(
      find.text('Drag the strip to scrub · Tap a frame to jump there'),
      findsOneWidget,
    );
    expect(find.text('Skip 1 second · hold to speed up'), findsNothing);
    expect(find.text('Step 1 frame'), findsNothing);
    expect(find.text('Enter'), findsNothing);
    expect(find.text('Backspace'), findsNothing);
    expect(find.text('Resume here'), findsOneWidget);
    expect(find.text('Back to live'), findsOneWidget);
  });

  testWidgets('gives the touch buttons a finger-sized target', (tester) async {
    await _pump(tester, method: InputMethod.touch);

    expect(_chipHeight(tester, 'Resume here'), greaterThanOrEqualTo(44));
    expect(_chipHeight(tester, 'Back to live'), greaterThanOrEqualTo(44));
  });

  testWidgets('keeps the key hints compact', (tester) async {
    await _pump(tester);

    expect(_chipHeight(tester, 'Resume here'), lessThan(44));
  });

  testWidgets('pairs the bound keys with their outcome', (tester) async {
    await _pump(tester);

    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Resume here'), findsOneWidget);
    expect(find.text('Backspace'), findsOneWidget);
    expect(find.text('Back to live'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('shows gamepad button labels after gamepad input', (
    tester,
  ) async {
    await _pump(tester, method: InputMethod.gamepad);

    expect(find.text('D-Pad Left'), findsOneWidget);
    expect(find.text('D-Pad Right'), findsOneWidget);
    expect(find.text('D-Pad Up'), findsOneWidget);
    expect(find.text('D-Pad Down'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Enter'), findsNothing);
  });

  testWidgets('follows a remapped binding', (tester) async {
    final bindings = [
      for (final binding in _defaultBindings)
        if (binding.action != cancel) binding,
      Binding(
        index: 0,
        action: cancel,
        input: InputCombination.keyboard({LogicalKeyboardKey.escape}),
      ),
    ];

    await _pump(tester, bindings: bindings);

    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Backspace'), findsNothing);
  });

  testWidgets('drops the hint for an unbound action', (tester) async {
    final bindings = [
      for (final binding in _defaultBindings)
        if (binding.action != confirm) binding,
    ];

    await _pump(tester, bindings: bindings);

    expect(find.text('Resume here'), findsNothing);
    expect(find.text('Back to live'), findsOneWidget);
  });

  testWidgets('sizes the fine step from the capture interval', (tester) async {
    await _pump(tester, state: _state(captureInterval: 4));

    expect(find.text('Step 4 frames'), findsOneWidget);
    expect(find.text('Step 1 frame'), findsNothing);
  });

  testWidgets('tapping the resume hint commits the scrub', (tester) async {
    var committed = 0;
    var cancelled = 0;

    await _pump(
      tester,
      onCommit: () => committed++,
      onCancel: () => cancelled++,
    );

    await tester.tap(find.text('Resume here'));
    await tester.pump();

    expect(committed, 1);
    expect(cancelled, 0);
  });

  testWidgets('tapping the back-to-live hint cancels the scrub', (
    tester,
  ) async {
    var committed = 0;
    var cancelled = 0;

    await _pump(
      tester,
      onCommit: () => committed++,
      onCancel: () => cancelled++,
    );

    await tester.tap(find.text('Back to live'));
    await tester.pump();

    expect(cancelled, 1);
    expect(committed, 0);
  });
}
