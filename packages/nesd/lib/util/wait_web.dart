import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Precise frame-pacing sleep for the web.
final _channel = web.MessageChannel()
  ..port1.onmessage = ((web.MessageEvent _) {
    _pending.removeFirst().complete();
  }).toJS;

final Queue<Completer<void>> _pending = Queue<Completer<void>>();

const _idleThreshold = Duration(milliseconds: 10);

Future<void> _yieldMacrotask() {
  final completer = Completer<void>();

  _pending.add(completer);

  // `Future.delayed` maps to `setTimeout`, which browsers clamp to a ~4 ms
  // minimum for chained timers and which only ever fires late, sometimes by
  // 10 ms+ depending on tab state.
  // Short (frame-pacing) sleeps avoid timers entirely: they spin on zero-delay
  // MessageChannel macrotasks, which aren't clamped and still let the browser
  // process input and rendering in between.
  _channel.port2.postMessage(null);

  return completer.future;
}

Future<void> wait(Duration duration) async {
  if (duration >= _idleThreshold) {
    // long sleeps don't need the precision, fall back to `setTimeout`
    return Future.delayed(duration);
  }

  if (duration <= Duration.zero) {
    // make sure we still yield to the event loop, so the tab doesn't freeze
    return _yieldMacrotask();
  }

  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < duration) {
    await _yieldMacrotask();
  }
}
