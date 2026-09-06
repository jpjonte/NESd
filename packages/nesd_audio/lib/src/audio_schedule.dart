typedef ScheduledSlot = ({int samples, double startTime});

const _renderQuantum = 128;

class AudioSchedule {
  AudioSchedule({
    required this.capacity,
    required this.sampleRate,
    required this.recoverSamples,
    required this.currentTime,
  });

  final int capacity;
  final int sampleRate;
  final int recoverSamples;

  final double Function() currentTime;

  double _anchorTime = 0;
  int _scheduled = 0;
  bool _starved = true;
  int _underruns = 0;
  int _overruns = 0;

  int get filled {
    if (_starved) {
      return 0;
    }

    final played = _played;
    final remaining = _scheduled - (played < 0 ? 0 : played);

    return remaining < 0 ? 0 : remaining;
  }

  int get underruns => _underruns;

  int get overruns => _overruns;

  int get _played {
    final elapsed = currentTime() - _anchorTime;

    return (elapsed * sampleRate).round();
  }

  ScheduledSlot push(int count) {
    if (_starved) {
      _anchor();
    } else if (_scheduled - _played < _renderQuantum) {
      _underruns++;
      _anchor();
    }

    final free = capacity - filled;

    if (free <= 0) {
      _overruns++;

      return (samples: 0, startTime: 0);
    }

    final written = count <= free ? count : free;

    if (written < count) {
      _overruns++;
    }

    final startTime = _anchorTime + _scheduled / sampleRate;

    _scheduled += written;

    return (samples: written, startTime: startTime);
  }

  void reset() {
    _scheduled = 0;
    _starved = true;
  }

  void resetStats() {
    _underruns = 0;
    _overruns = 0;
  }

  void _anchor() {
    _anchorTime = currentTime() + recoverSamples / sampleRate;
    _scheduled = 0;
    _starved = false;
  }
}
