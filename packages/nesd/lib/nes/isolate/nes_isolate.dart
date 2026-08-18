import 'dart:async';
import 'dart:isolate';

import 'package:es_compression/lz4.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/isolate_sink.dart';
import 'package:nesd/log/sink/telemetry_sink.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_config.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd_audio/nesd_audio.dart';

/// Entry point run inside the spawned isolate. Wires a [NesWorker] to a
/// fresh command [ReceivePort] and hands the port back to the host via
/// [IsolateReadyEvent].
void nesIsolateMain(NesIsolateConfig config) {
  if (config.lz4LibraryPath case final path?) {
    Lz4Codec.libraryPath = path;
  }

  if (config.audioLibraryPath case final path?) {
    NesdAudio.libraryPath = path;
  }

  NesdLog.install(
    NesdLog(
      isolate: 'emulator',
      minimumLevel: config.logLevel,
      sinks: [
        IsolateSink(send: config.hostPort.send),
        TelemetrySink(),
      ],
    ),
  );

  final commandPort = ReceivePort();
  final worker = NesWorker(
    send: config.hostPort.send,
    audioFactory: config.disableAudio
        ? () => defaultNesdAudio(nullDevice: true)
        : null,
  );

  // Serialize command handling: chaining onto a single future prevents two
  // async handlers (e.g. _loadRom and _stop) from interleaving. The
  // try/catch lives INSIDE the chain so one failing command surfaces as an
  // ErrorEvent without breaking the chain for later commands.
  var queue = Future<void>.value();

  commandPort.listen((message) {
    final command = message as NesCommand;

    queue = queue.then((_) async {
      try {
        await worker.handleCommand(command);
      } on Object catch (error, stackTrace) {
        log.emulator.error(
          'Command failed',
          error: error,
          stackTrace: stackTrace,
        );

        config.hostPort.send(ErrorEvent.from(error, stackTrace));
      }
    });
  });

  config.hostPort.send(IsolateReadyEvent(commandPort: commandPort.sendPort));
}

/// Testability seam for [NesIsolate]: the subset of its API that
/// `RemoteNes` depends on. Production code always constructs a real
/// [NesIsolate]; tests can inject a fake implementation without spawning an
/// isolate.
abstract class NesIsolateHandle {
  Stream<NesIsolateEvent> get events;

  void send(NesCommand command);

  Future<void> dispose();
}

/// Host-side handle to a spawned emulator isolate.
///
/// Wraps the raw [Isolate]/[ReceivePort] handshake and exposes a typed
/// command/event API: [send] pushes [NesCommand]s in, [events] is a
/// broadcast stream of [NesIsolateEvent]s out.
class NesIsolate implements NesIsolateHandle {
  NesIsolate._(
    this._isolate,
    this._receivePort,
    this._errorPort,
    this._exitPort,
    this._commandPort,
    this.events,
  );

  final Isolate _isolate;
  final ReceivePort _receivePort;
  final ReceivePort _errorPort;
  final ReceivePort _exitPort;
  final SendPort _commandPort;

  @override
  final Stream<NesIsolateEvent> events;

  bool _disposed = false;

  static Future<NesIsolate> spawn({
    String? lz4LibraryPath,
    String? audioLibraryPath,
    bool disableAudio = false,
    LogLevel logLevel = LogLevel.info,
  }) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    errorPort.listen((message) {
      // Isolate error notifications arrive as [error, stackTrace].
      final parts = (message as List).map((e) => e?.toString() ?? '').toList();

      receivePort.sendPort.send(
        ErrorEvent(
          message: parts.isNotEmpty ? parts.first : '',
          stackTrace: parts.length > 1 ? parts.sublist(1).join('\n') : null,
        ),
      );
    });

    exitPort.listen((_) {
      receivePort.sendPort.send(const StoppedEvent());
    });

    final isolate = await Isolate.spawn(
      nesIsolateMain,
      NesIsolateConfig(
        hostPort: receivePort.sendPort,
        lz4LibraryPath: lz4LibraryPath,
        audioLibraryPath: audioLibraryPath,
        disableAudio: disableAudio,
        logLevel: logLevel,
      ),
      errorsAreFatal: false,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
      debugName: 'nesd-emulator',
    );

    final events = receivePort
        .map((message) => message as NesIsolateEvent)
        .asBroadcastStream(
          onListen: (subscription) => subscription.resume(),
          // Pause the underlying subscription on cancel so pending messages are
          // buffered instead of discarded.
          onCancel: (subscription) => subscription.pause(),
        );

    final ready =
        await events.firstWhere((event) => event is IsolateReadyEvent)
            as IsolateReadyEvent;

    return NesIsolate._(
      isolate,
      receivePort,
      errorPort,
      exitPort,
      ready.commandPort,
      events,
    );
  }

  @override
  void send(NesCommand command) {
    if (_disposed) {
      return;
    }

    _commandPort.send(command);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _commandPort.send(const ShutdownCommand());

    await events
        .firstWhere((event) => event is StoppedEvent)
        .timeout(
          const Duration(seconds: 2),
          onTimeout: () => const StoppedEvent(),
        );

    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
    _errorPort.close();
    _exitPort.close();
  }
}
