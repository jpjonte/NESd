import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/log/log_colors.dart';

void main() {
  test('every channel gets its own distinct color', () {
    final colors = LogChannel.values.map(logChannelColor).toSet();

    expect(colors.length, LogChannel.values.length);
  });

  test('every level gets its own distinct color', () {
    final colors = LogLevel.values.map(logLevelColor).toSet();

    expect(colors.length, LogLevel.values.length);
  });

  test('channel colors avoid the warning and error level colors', () {
    for (final channel in LogChannel.values) {
      expect(
        logChannelColor(channel),
        isNot(
          anyOf(logLevelColor(LogLevel.warning), logLevelColor(LogLevel.error)),
        ),
        reason: 'a channel must never masquerade as a severity',
      );
    }
  });
}
