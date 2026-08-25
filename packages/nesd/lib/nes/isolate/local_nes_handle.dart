import 'dart:async';

import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_command_queue.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd_audio/nesd_audio.dart';

/// Runs a [NesWorker] on the current event loop (web has no isolates).
class LocalNesHandle implements NesIsolateHandle {
  LocalNesHandle({NesdAudio Function()? audioFactory}) {
    // Pause-on-cancel so events are buffered while no listener is attached.
    events = _controller.stream.asBroadcastStream(
      onListen: (subscription) => subscription.resume(),
      onCancel: (subscription) => subscription.pause(),
    );

    _worker = NesWorker(send: _controller.add, audioFactory: audioFactory);
    _queue = NesCommandQueue(
      handle: _worker.handleCommand,
      onError: _controller.add,
    );
  }

  static Future<NesIsolateHandle> spawn() async => LocalNesHandle();

  final StreamController<NesIsolateEvent> _controller =
      StreamController<NesIsolateEvent>();

  late final NesWorker _worker;

  late final NesCommandQueue _queue;

  bool _disposed = false;

  @override
  late final Stream<NesIsolateEvent> events;

  @override
  void send(NesCommand command) {
    if (_disposed) {
      return;
    }

    _queue.add(command);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    await _queue.idle;
    await _worker.shutdown();

    // Not awaited: with no listener attached the close would wait on the paused
    // broadcast subscription forever.
    unawaited(_controller.close());
  }
}
