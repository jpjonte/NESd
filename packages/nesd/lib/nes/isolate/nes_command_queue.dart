import 'package:nesd/log/log.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

/// Serializes command handling onto a single future chain so two async
/// handlers (e.g. load-ROM and stop) never interleave.
class NesCommandQueue {
  NesCommandQueue({required this.handle, required this.onError});

  final Future<void> Function(NesCommand command) handle;
  final void Function(ErrorEvent event) onError;

  Future<void> _queue = Future<void>.value();

  /// Completes once every command enqueued so far has been handled.
  Future<void> get idle => _queue;

  void add(NesCommand command) {
    _queue = _queue.then((_) async {
      // try/catch lives here so errors don't affect later commands
      try {
        await handle(command);
      } on Object catch (error, stackTrace) {
        log.emulator.error(
          'Command failed',
          error: error,
          stackTrace: stackTrace,
        );

        onError(ErrorEvent.from(error, stackTrace));
      }
    });
  }
}
