import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';

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

Future<void> _pump(
  WidgetTester tester, {
  RewindScrubState? state,
  bool touchHints = false,
  VoidCallback? onCommit,
  VoidCallback? onCancel,
}) async {
  final filmState = state ?? _state();

  await tester.pumpWidget(
    MaterialApp(
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
            touchHints: touchHints,
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

  testWidgets('swaps the key hints for drag and tap hints on touch', (
    tester,
  ) async {
    await _pump(tester, touchHints: true);

    expect(
      find.text('Drag the strip to scrub · Tap a frame to jump there'),
      findsOneWidget,
    );
    expect(find.text('Skip 1 second · hold to speed up'), findsNothing);
    expect(find.text('Step 1 frame'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Resume here'), findsOneWidget);
    expect(find.text('Back to live'), findsOneWidget);
  });

  testWidgets('gives the touch buttons a finger-sized target', (tester) async {
    await _pump(tester, touchHints: true);

    expect(_chipHeight(tester, 'Resume here'), greaterThanOrEqualTo(44));
    expect(_chipHeight(tester, 'Back to live'), greaterThanOrEqualTo(44));
  });

  testWidgets('keeps the key hints compact', (tester) async {
    await _pump(tester);

    expect(_chipHeight(tester, 'Resume here'), lessThan(44));
  });

  testWidgets('pairs the confirm and cancel prompts with their outcome', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Resume here'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
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
