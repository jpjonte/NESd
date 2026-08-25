/// Silent sink for the web backend, used when no real audio output exists
/// (e.g. insecure context, worklet setup failure).
///
/// Mirrors the native null device: it consumes samples in real time so
/// the pacing governor keeps the emulator running at full speed. Kept
/// free of js_interop so it can be unit-tested.
class SilentAudioSink {
  SilentAudioSink({
    required this.capacity,
    required this.sampleRate,
    int Function()? elapsedMicroseconds,
  }) : _elapsedMicroseconds = elapsedMicroseconds ?? _stopwatchClock();

  final int capacity;
  final int sampleRate;
  final int Function() _elapsedMicroseconds;

  int _pushed = 0;

  static int Function() _stopwatchClock() {
    final stopwatch = Stopwatch()..start();

    return () => stopwatch.elapsedMicroseconds;
  }

  int get filled {
    final consumed = _elapsedMicroseconds() * sampleRate ~/ 1000000;
    final fill = _pushed - consumed;

    if (fill < 0) {
      return 0;
    }

    return fill > capacity ? capacity : fill;
  }

  /// Returns how many of [count] samples fit, mirroring the real ring's
  /// short-write behavior.
  int push(int count) {
    final free = capacity - filled;

    if (free <= 0) {
      return 0;
    }

    final written = count <= free ? count : free;

    // Anchor bookkeeping to the consumed amount so a long idle period
    // cannot bank unlimited credit.
    final consumed = _elapsedMicroseconds() * sampleRate ~/ 1000000;

    if (_pushed < consumed) {
      _pushed = consumed;
    }

    _pushed += written;

    return written;
  }
}
