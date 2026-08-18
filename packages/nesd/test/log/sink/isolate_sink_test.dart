import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/isolate_sink.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

void main() {
  test('forwards every record as a LogEvent', () {
    final sent = <NesIsolateEvent>[];

    NesdLog(
        sinks: [IsolateSink(send: sent.add)],
        minimumLevel: LogLevel.debug,
        isolate: 'emulator',
      )
      ..rom.info('ROM loaded')
      ..telemetry.emit('NESD_AUDIO ts=1');

    expect(sent, hasLength(2));

    final first = sent.first as LogEvent;

    expect(first.record.message, 'ROM loaded');
    expect(first.record.channel, LogChannel.rom);
    expect(first.record.isolate, 'emulator');

    expect((sent.last as LogEvent).record.channel, LogChannel.telemetry);
  });

  test('is not flagged origin-only so the host still stores it', () {
    expect(IsolateSink(send: (_) {}).emitsAtOriginOnly, isFalse);
  });
}
