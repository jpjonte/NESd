import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class AudioContextResumer {
  AudioContextResumer(this._context);

  final web.AudioContext _context;

  bool _failureLogged = false;

  void resumeIfSuspended() {
    if (_context.state != 'suspended') {
      return;
    }

    unawaited(
      _context.resume().toDart.catchError((Object error) {
        if (!_failureLogged) {
          _failureLogged = true;

          web.console.warn(
            'nesd_audio: AudioContext.resume() failed: $error'.toJS,
          );
        }

        return null;
      }),
    );
  }
}
