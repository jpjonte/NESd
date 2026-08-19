import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/ui/log/log_screen.dart';
import 'package:nesd/ui/router/router.dart';

import '../robot.dart';

LogRecord _record(String message) => LogRecord(
  time: DateTime.utc(2026, 8, 18, 14, 3, 22, 145),
  level: LogLevel.warning,
  channel: LogChannel.rom,
  message: message,
  context: const {'mapper': 4},
);

void main() {
  test('export text honors includeContext', () {
    final records = [_record('one')];

    expect(
      formatRecordsForExport(records, includeContext: true),
      contains('{"mapper":4}'),
    );
    expect(
      formatRecordsForExport(records, includeContext: false),
      isNot(contains('mapper')),
    );
  });

  test('export text is one record per line, oldest first', () {
    final text = formatRecordsForExport([
      _record('one'),
      _record('two'),
    ], includeContext: false);

    final lines = text.split('\n');

    expect(lines, hasLength(2));
    expect(lines.first, endsWith('one'));
    expect(lines.last, endsWith('two'));
  });

  testWidgets('copy all puts the filtered records on the clipboard', (
    tester,
  ) async {
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

    NesdLog.install(
      NesdLog(sinks: [LogBufferSink()], minimumLevel: LogLevel.debug),
    );

    addTearDown(() => NesdLog.install(NesdLog()));

    NesdLog.instance.add(_record('older message'));
    NesdLog.instance.add(_record('newer message'));

    final robot = Robot(tester);

    await robot.pumpApp();

    robot.container.read(routerProvider).navigate(const LogRoute());

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LogScreen.copyAllKey));
    await tester.pumpAndSettle();

    expect(copied, isNotNull);

    final text = copied!;

    expect(
      text.indexOf('older message'),
      lessThan(text.indexOf('newer message')),
    );
  });
}
