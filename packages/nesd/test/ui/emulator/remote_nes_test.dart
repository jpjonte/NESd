import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';

import 'remote_nes_fixtures.dart';

FrameEvent _frameEvent(int address, {int width = 2, int height = 2}) =>
    FrameEvent(
      frameHandle: address,
      pixels: PointerFramePixels(address: address),
      width: width,
      height: height,
      frameTimeMicroseconds: 0,
      sleepTimeMicroseconds: 0,
      frame: 0,
      rewindSize: 0,
    );

void main() {
  group('RemoteFrameSource', () {
    final allocated = <Pointer<Uint8>>[];

    Pointer<Uint8> alloc(int size) {
      final pointer = malloc<Uint8>(size);

      allocated.add(pointer);

      return pointer;
    }

    tearDown(() {
      for (final pointer in allocated) {
        malloc.free(pointer);
      }

      allocated.clear();
    });

    test('drop-oldest releases the superseded frame', () {
      final commands = <NesCommand>[];
      final source = RemoteFrameSource(sendCommand: commands.add);
      var notifications = 0;

      source.addListener(() => notifications++);

      final a = alloc(16);
      final b = alloc(16);

      source
        ..addFrame(_frameEvent(a.address))
        ..addFrame(_frameEvent(b.address));

      expect(commands, [
        isA<ReleaseFrameCommand>().having(
          (c) => c.frameHandle,
          'frameHandle',
          a.address,
        ),
      ]);

      final handle = source.takeFrame();

      expect(handle, isNotNull);
      expect(handle!.id, b.address);
      expect(notifications, 2);
    });

    test('takeFrame transfers ownership; releaseFrame sends command', () {
      final commands = <NesCommand>[];
      final source = RemoteFrameSource(sendCommand: commands.add);

      final a = alloc(16);

      source.addFrame(_frameEvent(a.address));

      final handle = source.takeFrame();

      expect(handle, isNotNull);
      expect(source.takeFrame(), isNull);

      source.releaseFrame(handle!);

      expect(commands, [
        isA<ReleaseFrameCommand>().having(
          (c) => c.frameHandle,
          'frameHandle',
          a.address,
        ),
      ]);
    });

    test('clear releases the held frame and empties the source', () {
      final commands = <NesCommand>[];
      final source = RemoteFrameSource(sendCommand: commands.add);

      final a = alloc(16);

      source
        ..addFrame(_frameEvent(a.address))
        ..clear();

      expect(commands, [
        isA<ReleaseFrameCommand>().having(
          (c) => c.frameHandle,
          'frameHandle',
          a.address,
        ),
      ]);
      expect(source.takeFrame(), isNull);
    });

    test('clear on an empty source sends nothing', () {
      final commands = <NesCommand>[];
      final source = RemoteFrameSource(sendCommand: commands.add)..clear();

      expect(commands, isEmpty);
      expect(source.takeFrame(), isNull);
    });
  });

  group('RemoteNes', () {
    late RecordingNesIsolateHandle handle;

    setUp(() {
      handle = RecordingNesIsolateHandle();
    });

    tearDown(() => handle.dispose());

    RemoteNes build({Duration? requestTimeout}) => RemoteNes(
      isolate: handle,
      romInfo: testRomInfo(),
      fileHash: 'abc123',
      hasZapper: true,
      cartridgeInfo: testCartridgeInfo(),
      requestTimeout: requestTimeout ?? const Duration(seconds: 5),
    );

    test('exposes constructor fields', () {
      final remote = build();

      expect(remote.fileHash, 'abc123');
      expect(remote.hasZapper, isTrue);
      expect(remote.romInfo.file.name, 'test.nes');

      remote.dispose();
    });

    test('status mirrors update from StatusEvent', () async {
      final remote = build();

      expect(remote.running, isFalse);
      expect(remote.paused, isFalse);

      handle.emit(
        const StatusEvent(
          running: true,
          paused: true,
          fastForward: true,
          rewind: true,
        ),
      );

      await pumpEventQueue();

      expect(remote.running, isTrue);
      expect(remote.paused, isTrue);
      expect(remote.fastForward, isTrue);
      expect(remote.rewind, isTrue);

      remote.dispose();
    });

    test('fastForward setter sends SetFastForwardCommand', () {
      final remote = build()..fastForward = true;

      // Optimistic mirror update reflects the request immediately.
      expect(remote.fastForward, isTrue);
      expect(
        handle.commands.whereType<SetFastForwardCommand>().single.enabled,
        isTrue,
      );

      remote.fastForward = false;

      expect(remote.fastForward, isFalse);
      expect(
        handle.commands.whereType<SetFastForwardCommand>().last.enabled,
        isFalse,
      );

      remote.dispose();
    });

    test('fastForwardSpeed setter sends SetFastForwardSpeedCommand', () {
      final remote = build()..fastForwardSpeed = FastForwardSpeed.x3;

      expect(
        handle.commands.whereType<SetFastForwardSpeedCommand>().single.speed,
        FastForwardSpeed.x3,
      );

      remote.dispose();
    });

    test('rewind setter sends SetRewindCommand', () {
      final remote = build()..rewind = true;

      expect(remote.rewind, isTrue);
      expect(
        handle.commands.whereType<SetRewindCommand>().single.enabled,
        isTrue,
      );

      remote.rewind = false;

      expect(remote.rewind, isFalse);
      expect(
        handle.commands.whereType<SetRewindCommand>().last.enabled,
        isFalse,
      );

      remote.dispose();
    });

    test('frame events feed frameSource', () async {
      final remote = build();
      final pointer = malloc<Uint8>(2 * 2 * 4);

      addTearDown(() => malloc.free(pointer));

      handle.emit(_frameEvent(pointer.address));

      await pumpEventQueue();

      final frame = remote.frameSource.takeFrame();

      expect(frame, isNotNull);
      expect(frame!.id, pointer.address);
      expect(frame.pixelPointer, pointer.address);

      remote.dispose();
    });

    test('RomLoadedEvent clears a held frame', () async {
      final remote = build();
      final pointer = malloc<Uint8>(2 * 2 * 4);

      addTearDown(() => malloc.free(pointer));

      handle.emit(_frameEvent(pointer.address));

      await pumpEventQueue();

      handle.emit(const RomLoadedEvent(hasZapper: false));

      await pumpEventQueue();

      expect(remote.frameSource.takeFrame(), isNull);
      expect(
        handle.commands,
        contains(
          isA<ReleaseFrameCommand>().having(
            (c) => c.frameHandle,
            'frameHandle',
            pointer.address,
          ),
        ),
      );

      remote.dispose();
    });

    test('requestSaveState resolves with matching requestId', () async {
      final remote = build();

      final future = remote.requestSaveState();
      final request = handle.commands.whereType<SaveStateRequest>().single;
      final bytes = Uint8List.fromList([1, 2, 3]);

      handle.emit(
        SaveStateResponse(
          requestId: request.requestId,
          state: NesBytes.fromList([bytes]),
        ),
      );

      expect(await future, bytes);

      remote.dispose();
    });

    test('requestSaveState times out to null', () async {
      final remote = build(requestTimeout: const Duration(milliseconds: 10));

      expect(await remote.requestSaveState(), isNull);

      remote.dispose();
    });

    test('a timed-out request is logged rather than vanishing', () async {
      final logged = <LogRecord>[];

      NesdLog.install(
        NesdLog(sinks: [_RecordingSink(logged)], minimumLevel: LogLevel.debug),
      );

      addTearDown(() => NesdLog.install(NesdLog()));

      final remote = build(requestTimeout: const Duration(milliseconds: 10));

      expect(await remote.requestSaveState(), isNull);

      final record = logged.singleWhere(
        (r) => r.channel == LogChannel.emulator,
      );

      expect(record.level, LogLevel.warning);
      expect(
        record.message,
        contains('timed out'),
        reason:
            'a request that silently resolves to null leaves the user '
            'with a missing save state and no explanation anywhere',
      );

      remote.dispose();
    });

    test('a late response after timeout does not throw', () async {
      final remote = build(requestTimeout: const Duration(milliseconds: 10));

      expect(await remote.requestSaveState(), isNull);

      final request = handle.commands.whereType<SaveStateRequest>().single;

      handle.emit(
        SaveStateResponse(
          requestId: request.requestId,
          state: NesBytes.fromList([Uint8List(0)]),
        ),
      );

      // If the response handler threw on the already-removed completer,
      // this pump would surface it as an uncaught async error and fail
      // the test.
      await pumpEventQueue();

      remote.dispose();
    });

    test('requestSram resolves with matching requestId', () async {
      final remote = build();

      final future = remote.requestSram();
      final request = handle.commands.whereType<SaveSramRequest>().single;
      final bytes = Uint8List.fromList([4, 5, 6]);

      handle.emit(
        SramResponse(
          requestId: request.requestId,
          sram: NesBytes.fromList([bytes]),
        ),
      );

      expect(await future, bytes);

      remote.dispose();
    });

    test('requestThumbnail resolves pixels/width/height', () async {
      final remote = build();

      final future = remote.requestThumbnail();
      final request = handle.commands.whereType<ThumbnailRequest>().single;
      final pixels = Uint8List.fromList([9, 9, 9, 9]);

      handle.emit(
        ThumbnailResponse(
          requestId: request.requestId,
          pixels: NesBytes.fromList([pixels]),
          width: 1,
          height: 1,
        ),
      );

      final result = await future;

      expect(result, isNotNull);
      expect(result!.pixels, pixels);
      expect(result.width, 1);
      expect(result.height, 1);

      remote.dispose();
    });

    test('requestTileDebug resolves the raw response', () async {
      final remote = build();

      final future = remote.requestTileDebug();
      final request = handle.commands.whereType<TileDebugRequest>().single;

      handle.emit(
        TileDebugResponse(
          requestId: request.requestId,
          ppuMemory: NesBytes.fromList([Uint8List(0x4000)]),
          ppuCtrl: 1,
          v: 2,
          t: 3,
          x: 4,
        ),
      );

      final result = await future;

      expect(result, isNotNull);
      expect(result!.ppuCtrl, 1);
      expect(result.v, 2);
      expect(result.t, 3);
      expect(result.x, 4);

      remote.dispose();
    });

    test('fire-and-forget commands send expected messages', () {
      final remote = build()
        ..buttonDown(0, NesButton.a)
        ..buttonUp(0, NesButton.a)
        ..buttonToggle(1, NesButton.start)
        ..pause()
        ..unpause()
        ..togglePause()
        ..suspend()
        ..resume()
        ..reset()
        ..toggleFastForward()
        ..toggleRewind()
        ..stepInto()
        ..stepOver()
        ..stepOut()
        ..runUntilFrame()
        ..rewindEnabled = true
        ..region = Region.pal
        ..cheats = const []
        ..volume = 0.5
        ..lowPassFilter = true
        ..breakpoints = const []
        ..addBreakpoint(Breakpoint(0x8000))
        ..removeBreakpoint(0x8000)
        ..setDebuggerActive(true)
        ..setExecutionLogEnabled(true)
        ..setZapperPosition(const Offset(1, 2))
        ..zapperPull()
        ..zapperRelease()
        ..loadState(Uint8List.fromList([1]))
        ..loadSram(Uint8List.fromList([2]));

      expect(remote.zapperPosition.value, const Offset(1, 2));

      expect(handle.commands, [
        isA<ButtonDownCommand>(),
        isA<ButtonUpCommand>(),
        isA<ButtonToggleCommand>(),
        isA<PauseCommand>(),
        isA<UnpauseCommand>(),
        isA<TogglePauseCommand>(),
        isA<SuspendCommand>(),
        isA<ResumeCommand>(),
        isA<ResetCommand>(),
        isA<ToggleFastForwardCommand>(),
        isA<ToggleRewindCommand>(),
        isA<StepIntoCommand>(),
        isA<StepOverCommand>(),
        isA<StepOutCommand>(),
        isA<RunUntilFrameCommand>(),
        isA<SetRewindEnabledCommand>(),
        isA<SetRegionCommand>(),
        isA<SetCheatsCommand>(),
        isA<SetVolumeCommand>(),
        isA<SetLowPassFilterCommand>(),
        isA<SetBreakpointsCommand>(),
        isA<AddBreakpointCommand>(),
        isA<RemoveBreakpointCommand>(),
        isA<SetDebuggerActiveCommand>(),
        isA<SetExecutionLogEnabledCommand>(),
        isA<SetZapperPositionCommand>(),
        isA<ZapperPullCommand>(),
        isA<ZapperReleaseCommand>(),
        isA<LoadStateCommand>(),
        isA<LoadSramCommand>(),
      ]);

      remote.dispose();
    });

    test('setZapperPosition(null) clears the mirror', () {
      final remote = build()..setZapperPosition(const Offset(1, 2));

      expect(remote.zapperPosition.value, isNotNull);

      remote.setZapperPosition(null);

      expect(remote.zapperPosition.value, isNull);

      final command = handle.commands
          .whereType<SetZapperPositionCommand>()
          .last;

      expect(command.x, isNull);
      expect(command.y, isNull);

      remote.dispose();
    });

    test('setZapperPosition updates the crosshair notifier', () {
      final handle = RecordingNesIsolateHandle();

      final nes = RemoteNes(
        isolate: handle,
        romInfo: testRomInfo(),
        fileHash: 'hash',
        hasZapper: true,
        cartridgeInfo: testCartridgeInfo(),
      );

      addTearDown(nes.dispose);

      var notified = 0;

      nes.zapperPosition.addListener(() => notified++);

      nes.setZapperPosition(const Offset(12, 34));

      expect(nes.zapperPosition.value, const Offset(12, 34));
      expect(notified, 1);

      final command = handle.commands
          .whereType<SetZapperPositionCommand>()
          .single;

      expect(command.x, 12);
      expect(command.y, 34);
    });

    test(
      'stop sends StopCommand, awaits StoppedEvent, clears frames',
      () async {
        final remote = build();
        final pointer = malloc<Uint8>(2 * 2 * 4);

        addTearDown(() => malloc.free(pointer));

        handle.emit(_frameEvent(pointer.address));

        await pumpEventQueue();

        final stopFuture = remote.stop();

        expect(handle.commands, contains(isA<StopCommand>()));

        handle.emit(const StoppedEvent());

        await stopFuture;

        expect(remote.frameSource.takeFrame(), isNull);

        remote.dispose();
      },
    );

    test(
      'stop completes after requestTimeout when no StoppedEvent arrives',
      () async {
        final remote = build(requestTimeout: const Duration(milliseconds: 10));

        // No StoppedEvent is ever emitted; the wait must still complete
        // instead of hanging forever.
        await remote.stop();

        expect(handle.commands, contains(isA<StopCommand>()));

        remote.dispose();
      },
    );

    test(
      'dispose cancels the subscription without sending a command',
      () async {
        final remote = build();
        final commandCountBefore = handle.commands.length;

        remote.dispose();

        handle.emit(
          const StatusEvent(
            running: true,
            paused: false,
            fastForward: false,
            rewind: false,
          ),
        );

        await pumpEventQueue();

        expect(remote.running, isFalse);
        expect(handle.commands.length, commandCountBefore);
      },
    );
  });
}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}
