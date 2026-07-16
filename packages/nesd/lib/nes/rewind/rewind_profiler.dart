/// Per-stage timing accumulator for the rewind pipeline.
///
/// One line per [windowSize] captures:
/// `NESD_REWIND_PROF frames=<n> cap_us=<n> ser_us=<n> diff_us=<n>`
/// `comp_us=<n>` — a stable wire format scraped from logcat during
/// measurement runs. Instances exist only in profiling builds (see
/// [maybeRewindProfiler]); production passes null and pays only a
/// null check per stage per capture.
class RewindProfiler {
  RewindProfiler({this.windowSize = 60});

  final int windowSize;

  int _captures = 0;
  int _captureMicros = 0;
  int _serializeMicros = 0;
  int _diffMicros = 0;
  int _compressMicros = 0;

  void addCapture(int us) {
    _captureMicros += us;
    _captures++;

    if (_captures >= windowSize) {
      _print();
    }
  }

  void addSerialize(int us) => _serializeMicros += us;

  void addDiff(int us) => _diffMicros += us;

  void addCompress(int us) => _compressMicros += us;

  void _print() {
    // ignore: avoid_print - logcat is the transport for measurements
    print(
      'NESD_REWIND_PROF frames=$_captures cap_us=$_captureMicros '
      'ser_us=$_serializeMicros diff_us=$_diffMicros '
      'comp_us=$_compressMicros',
    );

    _captures = 0;
    _captureMicros = 0;
    _serializeMicros = 0;
    _diffMicros = 0;
    _compressMicros = 0;
  }
}

/// Compile-time gate: `--dart-define=NESD_REWIND_PROF=true` builds
/// return an instance; everything else returns null.
RewindProfiler? maybeRewindProfiler() {
  const enabled = bool.fromEnvironment('NESD_REWIND_PROF');

  return enabled ? RewindProfiler() : null;
}
