import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _FakeNesIsolateHandle implements NesIsolateHandle {
  final StreamController<NesIsolateEvent> _controller =
      StreamController<NesIsolateEvent>.broadcast();

  final List<NesCommand> commands = [];

  @override
  Stream<NesIsolateEvent> get events => _controller.stream;

  @override
  void send(NesCommand command) {
    commands.add(command);
  }

  void emit(NesIsolateEvent event) => _controller.add(event);

  @override
  Future<void> dispose() => _controller.close();

  Future<void> close() => _controller.close();
}

RomInfo _testRomInfo() => const RomInfo(
  file: FilesystemFile(
    path: 'test.nes',
    name: 'test.nes',
    type: FilesystemFileType.file,
  ),
);

FrameEvent _frameEvent(int pointerAddress, {int width = 2, int height = 2}) =>
    FrameEvent(
      pointerAddress: pointerAddress,
      width: width,
      height: height,
      frameTimeMicroseconds: 0,
      sleepBudgetMicroseconds: 0,
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
          (c) => c.pointerAddress,
          'pointerAddress',
          a.address,
        ),
      ]);

      final handle = source.takeFrame();

      expect(handle, isNotNull);
      expect(handle!.pointerAddress, b.address);
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
          (c) => c.pointerAddress,
          'pointerAddress',
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
          (c) => c.pointerAddress,
          'pointerAddress',
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
    late _FakeNesIsolateHandle handle;

    setUp(() {
      handle = _FakeNesIsolateHandle();
    });

    tearDown(() => handle.close());

    RemoteNes build({Duration? requestTimeout}) => RemoteNes(
      isolate: handle,
      romInfo: _testRomInfo(),
      fileHash: 'abc123',
      hasZapper: true,
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
      expect(frame!.pointerAddress, pointer.address);

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
            (c) => c.pointerAddress,
            'pointerAddress',
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
          state: TransferableTypedData.fromList([bytes]),
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

    test('a late response after timeout does not throw', () async {
      final remote = build(requestTimeout: const Duration(milliseconds: 10));

      expect(await remote.requestSaveState(), isNull);

      final request = handle.commands.whereType<SaveStateRequest>().single;

      handle.emit(
        SaveStateResponse(
          requestId: request.requestId,
          state: TransferableTypedData.fromList([Uint8List(0)]),
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
          sram: TransferableTypedData.fromList([bytes]),
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
          pixels: TransferableTypedData.fromList([pixels]),
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
          ppuMemory: TransferableTypedData.fromList([Uint8List(0x4000)]),
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

      expect(remote.zapperPosition, const Offset(1, 2));

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

      expect(remote.zapperPosition, isNotNull);

      remote.setZapperPosition(null);

      expect(remote.zapperPosition, isNull);

      final command = handle.commands
          .whereType<SetZapperPositionCommand>()
          .last;

      expect(command.x, isNull);
      expect(command.y, isNull);

      remote.dispose();
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
