import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/ui/log/log_channel_filter.dart';
import 'package:nesd/ui/log/log_colors.dart';
import 'package:nesd/ui/log/log_record_tile.dart';
import 'package:nesd/ui/log/log_screen.dart';
import 'package:nesd/ui/log/log_search_field.dart';
import 'package:nesd/ui/log/log_view_filter.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/debug/view_log_button.dart';

import '../robot.dart';

LogRecord _record({
  required String message,
  LogLevel level = LogLevel.info,
  LogChannel channel = LogChannel.app,
  Map<String, Object?>? context,
}) => LogRecord(
  time: DateTime(2026, 8, 18, 14, 3, 22, 145),
  level: level,
  channel: channel,
  message: message,
  context: context,
);

void main() {
  setUp(() {
    NesdLog.install(
      NesdLog(sinks: [LogBufferSink()], minimumLevel: LogLevel.debug),
    );
  });

  tearDown(() => NesdLog.install(NesdLog()));

  Future<void> openLog(
    Robot robot, {
    List<LogRecord> records = const [],
  }) async {
    await robot.pumpApp();

    NesdLog.instance.sinkOfType<LogBufferSink>()!.clear();

    for (final record in records) {
      NesdLog.instance.add(record);
    }

    robot.container.read(routerProvider).navigate(const LogRoute());

    await robot.tester.pumpAndSettle();
  }

  testWidgets('shows an empty state when nothing has been logged', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(robot);

    expect(find.byKey(LogScreen.emptyKey), findsOneWidget);
  });

  testWidgets('lists buffered records', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'first message'),
        _record(message: 'second message'),
      ],
    );

    expect(find.byType(LogRecordTile), findsNWidgets(2));
    expect(find.textContaining('first message'), findsOneWidget);
  });

  testWidgets('filters by minimum level', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'a debug line', level: LogLevel.debug),
        _record(message: 'an error line', level: LogLevel.error),
      ],
    );

    expect(find.byType(LogRecordTile), findsNWidgets(2));

    await tester.tap(find.byKey(LogScreen.levelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Error').last);
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);
    expect(find.textContaining('an error line'), findsOneWidget);
  });

  testWidgets('"Only" narrows the list to a single channel', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'rom line', channel: LogChannel.rom),
        _record(message: 'audio line', channel: LogChannel.audio),
      ],
    );

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogChannelFilter.onlyKey(LogChannel.rom)));
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);
    expect(find.textContaining('rom line'), findsOneWidget);
  });

  testWidgets('unchecking a channel hides just that channel', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'rom line', channel: LogChannel.rom),
        _record(message: 'audio line', channel: LogChannel.audio),
      ],
    );

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(LogChannelFilter.checkboxKey(LogChannel.audio)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('rom line'), findsOneWidget);
    expect(find.textContaining('audio line'), findsNothing);
  });

  testWidgets('"All" restores every channel after "Only"', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'rom line', channel: LogChannel.rom),
        _record(message: 'audio line', channel: LogChannel.audio),
      ],
    );

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogChannelFilter.onlyKey(LogChannel.rom)));
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogChannelFilter.allKey));
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsNWidgets(2));
  });

  testWidgets('unchecking every channel shows the empty state', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [_record(message: 'rom line', channel: LogChannel.rom)],
    );

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();

    for (final channel in LogChannel.values) {
      await tester.tap(find.byKey(LogChannelFilter.checkboxKey(channel)));
      await tester.pumpAndSettle();
    }

    expect(find.byType(LogRecordTile), findsNothing);
    expect(find.byKey(LogScreen.emptyKey), findsOneWidget);
  });

  testWidgets('filters persist across leaving and reopening the screen', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'a debug line', level: LogLevel.debug),
        _record(message: 'an error line', level: LogLevel.error),
      ],
    );

    await tester.tap(find.byKey(LogScreen.levelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Error').last);
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    expect(
      find.byType(LogScreen),
      findsNothing,
      reason: 'popping must dispose the screen for this test to mean anything',
    );

    robot.container.read(routerProvider).navigate(const LogRoute());
    await tester.pumpAndSettle();

    expect(
      find.byType(LogRecordTile),
      findsOneWidget,
      reason: 'the level filter should survive leaving the screen',
    );
    expect(find.textContaining('an error line'), findsOneWidget);
  });

  testWidgets('the search field narrows the list to matching rows', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'audio buffer underrun'),
        _record(message: 'mapper switched bank'),
      ],
    );

    await tester.enterText(find.byKey(LogScreen.searchFieldKey), 'AUDIO');
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);
    expect(find.textContaining('audio buffer underrun'), findsOneWidget);
  });

  testWidgets('an all-excluding search says so instead of "nothing logged"', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(robot, records: [_record(message: 'a line')]);

    await tester.enterText(
      find.byKey(LogScreen.searchFieldKey),
      'matches nothing',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LogScreen.emptyKey), findsOneWidget);
    expect(find.text('No matching records'), findsOneWidget);
    expect(find.text('Nothing logged yet'), findsNothing);
  });

  testWidgets('counts how many records the filters kept', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'a debug line', level: LogLevel.debug),
        _record(message: 'an error line', level: LogLevel.error),
      ],
    );

    expect(
      tester.widget<Text>(find.byKey(LogScreen.counterKey)).data,
      '2 of 2',
    );

    await tester.tap(find.byKey(LogScreen.levelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Error').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(LogScreen.counterKey)).data,
      '1 of 2',
    );
  });

  testWidgets('the clear button empties the search and restores the list', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'audio buffer underrun'),
        _record(message: 'mapper switched bank'),
      ],
    );

    await tester.enterText(find.byKey(LogScreen.searchFieldKey), 'audio');
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);

    await tester.tap(find.byKey(LogSearchField.clearKey));
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsNWidgets(2));

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LogScreen.searchFieldKey),
        matching: find.byType(TextField),
      ),
    );

    expect(field.controller!.text, isEmpty);
  });

  testWidgets('externally clearing the search also empties the field', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'audio buffer underrun'),
        _record(message: 'mapper switched bank'),
      ],
    );

    await tester.enterText(find.byKey(LogScreen.searchFieldKey), 'audio');
    await tester.pumpAndSettle();

    robot.container.read(logViewFilterProvider.notifier).search = '';
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsNWidgets(2));

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LogScreen.searchFieldKey),
        matching: find.byType(TextField),
      ),
    );

    expect(
      field.controller!.text,
      isEmpty,
      reason: 'the field must follow the filter state, not just seed from it',
    );
  });

  testWidgets('the search text survives leaving and reopening the screen', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'audio buffer underrun'),
        _record(message: 'mapper switched bank'),
      ],
    );

    await tester.enterText(find.byKey(LogScreen.searchFieldKey), 'audio');
    await tester.pumpAndSettle();

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    robot.container.read(routerProvider).navigate(const LogRoute());
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LogScreen.searchFieldKey),
        matching: find.byType(TextField),
      ),
    );

    expect(
      field.controller!.text,
      'audio',
      reason: 'the field must show the search that is still being applied',
    );
  });

  testWidgets('the channel selection survives leaving and reopening', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'rom line', channel: LogChannel.rom),
        _record(message: 'audio line', channel: LogChannel.audio),
      ],
    );

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LogChannelFilter.onlyKey(LogChannel.rom)));
    await tester.pumpAndSettle();

    await robot.container.read(routerProvider).maybePop();
    await tester.pumpAndSettle();

    robot.container.read(routerProvider).navigate(const LogRoute());
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsOneWidget);
    expect(find.textContaining('rom line'), findsOneWidget);
  });

  testWidgets(
    'rows color the timestamp, level tag, channel, and message independently',
    (tester) async {
      final robot = Robot(tester);

      final record = _record(
        message: 'buffer underrun',
        level: LogLevel.warning,
        channel: LogChannel.audio,
      );

      await openLog(robot, records: [record]);

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(LogRecordTile),
          matching: find.byType(Text),
        ),
      );

      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();

      expect(
        text.textSpan!.toPlainText(),
        formatRecordForViewer(record),
        reason: 'coloring must not change the rendered text itself',
      );
      expect(spans[0].style!.color, logTimestampColor);
      expect(spans[1].style!.color, logLevelColor(LogLevel.warning));
      expect(spans[2].style!.color, logChannelColor(LogChannel.audio));
      expect(spans[3].style!.color, logLevelColor(LogLevel.warning));
    },
  );

  testWidgets('the channel menu marks each channel with its color', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(robot, records: [_record(message: 'a line')]);

    await tester.tap(find.byKey(LogScreen.channelFilterKey));
    await tester.pumpAndSettle();

    for (final channel in LogChannel.values) {
      final dot = tester.widget<Container>(
        find.byKey(LogChannelFilter.dotKey(channel)),
      );

      final decoration = dot.decoration! as BoxDecoration;

      expect(
        decoration.color,
        logChannelColor(channel),
        reason: 'the ${channel.name} dot must match its row color',
      );
    }
  });

  testWidgets('expands a row to reveal its context', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'with context', context: {'mapper': 4}),
      ],
    );

    expect(find.textContaining('"mapper"'), findsNothing);

    await tester.tap(find.byType(LogRecordTile));
    await tester.pumpAndSettle();

    expect(find.textContaining('"mapper"'), findsOneWidget);
  });

  testWidgets('rows without details do not expand', (tester) async {
    final robot = Robot(tester);

    await openLog(robot, records: [_record(message: 'plain')]);

    final tile = tester.widget<LogRecordTile>(find.byType(LogRecordTile));

    expect(tile.record.hasDetails, isFalse);
    expect(find.byType(SelectableText), findsNothing);

    await tester.tap(find.byType(LogRecordTile));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('renders the newest record at the bottom', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'older line'),
        _record(message: 'newer line'),
      ],
    );

    final olderY = tester.getTopLeft(find.textContaining('older line')).dy;
    final newerY = tester.getTopLeft(find.textContaining('newer line')).dy;

    expect(
      newerY,
      greaterThan(olderY),
      reason:
          'the newest record ("newer line") should render below the older one',
    );
  });

  testWidgets('keeps a row expanded by identity when a new record arrives', (
    tester,
  ) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'expanded one', context: {'mapper': 4}),
      ],
    );

    await tester.tap(find.byType(LogRecordTile));
    await tester.pumpAndSettle();

    expect(find.textContaining('"mapper"'), findsOneWidget);

    NesdLog.instance.add(_record(message: 'freshly arrived'));

    await tester.pumpAndSettle();

    expect(
      find.textContaining('"mapper"'),
      findsOneWidget,
      reason: 'the originally expanded row should stay expanded',
    );
    expect(find.textContaining('freshly arrived'), findsOneWidget);
    expect(
      find.byType(SelectableText),
      findsOneWidget,
      reason: 'the newly arrived row should not inherit the expanded state',
    );
  });

  testWidgets('only expandable rows show an expand chevron', (tester) async {
    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'plain line'),
        _record(message: 'detailed line', context: {'mapper': 4}),
      ],
    );

    expect(
      find.byIcon(Icons.chevron_right),
      findsOneWidget,
      reason: 'exactly the one row with details should advertise expansion',
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('the row copy button copies just that record', (tester) async {
    String? copied;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }

        return null;
      },
    );

    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final robot = Robot(tester);

    await openLog(
      robot,
      records: [
        _record(message: 'first line'),
        _record(message: 'second line'),
      ],
    );

    final secondTile = find.ancestor(
      of: find.textContaining('second line'),
      matching: find.byType(LogRecordTile),
    );

    await tester.tap(
      find.descendant(
        of: secondTile,
        matching: find.byIcon(Icons.content_copy),
      ),
    );
    await tester.pumpAndSettle();

    expect(copied, isNotNull);
    expect(
      copied,
      isNot(contains('first line')),
      reason: 'copying one row must not drag in its neighbors',
    );
    expect(copied, contains('second line'));
  });

  testWidgets('clear empties the buffer', (tester) async {
    final robot = Robot(tester);

    await openLog(robot, records: [_record(message: 'goes away')]);

    await tester.tap(find.byKey(LogScreen.clearKey));
    await tester.pumpAndSettle();

    expect(find.byType(LogRecordTile), findsNothing);
    expect(find.byKey(LogScreen.emptyKey), findsOneWidget);
  });

  testWidgets('the debug tab button opens the log viewer', (tester) async {
    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const SettingsRoute());

    await tester.pumpAndSettle();

    await robot.settingsScreen.tapDebugTab();

    robot.settingsScreen.debug.expectViewLogButtonFound();

    await robot.go(find.byType(ViewLogButton));

    expect(find.byType(LogScreen), findsOneWidget);
  });
}
