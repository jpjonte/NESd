import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void _echo(SendPort port) {
  final receivePort = ReceivePort();

  port.send(receivePort.sendPort);

  receivePort.listen(port.send);
}

Future<Object?> _roundTrip(Object message) async {
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(_echo, receivePort.sendPort);
  final stream = receivePort.asBroadcastStream();

  (await stream.first as SendPort).send(message);

  final result = await stream.first;

  isolate.kill(priority: Isolate.immediate);
  receivePort.close();

  return result;
}

void main() {
  test('LoadRomCommand round-trips through an isolate', () async {
    final command = LoadRomCommand(
      rom: TransferableTypedData.fromList([
        Uint8List.fromList([1, 2, 3]),
      ]),
      file: const FilesystemFile(
        path: '/tmp/a.nes',
        name: 'a.nes',
        type: FilesystemFileType.file,
      ),
      databaseEntry: null,
      region: Region.ntsc,
      rewindEnabled: true,
      cheats: const [],
      breakpoints: const [],
    );

    final result = await _roundTrip(command);

    expect(result, isA<LoadRomCommand>());
    expect(
      (result! as LoadRomCommand).rom.materialize().asUint8List(),
      equals([1, 2, 3]),
    );
  });

  test('simple commands round-trip', () async {
    final commands = <NesCommand>[
      const ButtonDownCommand(controller: 0, button: NesButton.a),
      const SetRegionCommand(region: Region.pal),
      const SetFastForwardCommand(enabled: true),
      const SetRewindCommand(enabled: false),
      const ReleaseFrameCommand(pointerAddress: 0xdeadbeef),
      const SetZapperPositionCommand(x: 12, y: 34),
      AddBreakpointCommand(breakpoint: Breakpoint(0x8000)),
    ];

    for (final command in commands) {
      final result = await _roundTrip(command);

      expect(result.runtimeType, command.runtimeType);
    }
  });

  test('FrameEvent and StatusEvent round-trip', () async {
    const frame = FrameEvent(
      pointerAddress: 1234,
      width: 256,
      height: 240,
      frameTimeMicroseconds: 16600,
      sleepTimeMicroseconds: 100,
      frame: 42,
      rewindSize: 0,
    );

    final result = await _roundTrip(frame);

    expect(result, isA<FrameEvent>());
    expect((result! as FrameEvent).pointerAddress, 1234);

    const status = StatusEvent(
      running: true,
      paused: false,
      fastForward: false,
      rewind: false,
    );

    expect(await _roundTrip(status), isA<StatusEvent>());
  });

  test('DebuggerEvent with DebuggerState round-trips', () async {
    final event = DebuggerEvent(
      state: const DebuggerState(),
      cpuMemory: TransferableTypedData.fromList([Uint8List(0x10000)]),
    );

    final result = await _roundTrip(event);

    expect(result, isA<DebuggerEvent>());
  });

  test('AudioStatsEvent round-trips through an isolate', () async {
    const event = AudioStatsEvent(
      timestampMilliseconds: 1234,
      exhaustDelta: 2,
      fullDelta: 1,
      fillMin: 240,
      fillMax: 2000,
    );

    final result = await _roundTrip(event);

    expect(result, isA<AudioStatsEvent>());

    final typed = result! as AudioStatsEvent;

    expect(typed.exhaustDelta, 2);
    expect(
      typed.logLine,
      'NESD_AUDIO ts=1234 exhaust=2 full=1 fill_min=240 fill_max=2000',
    );
  });

  test('StartPcmDumpCommand round-trips through an isolate', () async {
    final result = await _roundTrip(
      const StartPcmDumpCommand(path: '/tmp/a.pcm'),
    );

    expect(result, isA<StartPcmDumpCommand>());
    expect((result! as StartPcmDumpCommand).path, '/tmp/a.pcm');
  });

  test('StopPcmDumpCommand round-trips through an isolate', () async {
    expect(
      await _roundTrip(const StopPcmDumpCommand()),
      isA<StopPcmDumpCommand>(),
    );
  });
}
