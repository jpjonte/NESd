import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

void main() {
  group('ErrorEvent', () {
    test('from separates the message from the stack trace', () {
      final event = ErrorEvent.from(
        ArgumentError('boom'),
        StackTrace.fromString('#0      main (file.dart:1)'),
      );

      expect(event.message, 'Invalid argument(s): boom');
      expect(event.stackTrace, '#0      main (file.dart:1)');
    });

    test('stack trace defaults to null', () {
      const event = ErrorEvent(message: 'boom');

      expect(event.stackTrace, isNull);
    });
  });
}
