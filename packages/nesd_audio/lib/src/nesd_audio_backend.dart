import 'dart:typed_data';

import 'package:nesd_audio/src/nesd_audio_state.dart';

/// Push-model PCM audio output.
abstract interface class NesdAudioBackend {
  /// Buffer capacity in samples.
  int get capacity;

  /// Samples currently buffered (estimated on web).
  int get filled;

  /// Underruns since the last [resetStats].
  int get underruns;

  /// Overruns (short writes) since the last [resetStats].
  int get overruns;

  /// Largest single device read since last [resetStats] (0 where not tracked).
  int get popMax;

  /// Device restarts after OS-initiated stops; always 0 on web.
  int get restarts;

  NesdAudioState get state;

  /// Pushes samples and returns how many were written. A short write
  /// means the buffer was near capacity.
  int push(Float32List samples);

  /// Drops buffered samples.
  void reset();

  void resetStats();

  void close();
}
