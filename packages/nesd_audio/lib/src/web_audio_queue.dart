/// Fill accounting for the web audio backend.
class WebAudioQueue {
  WebAudioQueue({required this.capacity});

  final int capacity;

  int _estimatedFill = 0;
  int _totalPushed = 0;
  int _underruns = 0;
  int _overruns = 0;

  /// May briefly exceed [capacity] right after a report. [push] treats
  /// [capacity] as a hard limit.
  int get estimatedFill => _estimatedFill;

  int get underruns => _underruns;

  int get overruns => _overruns;

  int push(int count) {
    final free = capacity - _estimatedFill;

    if (free <= 0) {
      _overruns++;

      return 0;
    }

    final written = count <= free ? count : free;

    if (written < count) {
      _overruns++;
    }

    _estimatedFill += written;
    _totalPushed += written;

    return written;
  }

  /// Re-anchors the estimate from a worklet report. [received] is the
  /// worklet's running total of samples that had reached it when the
  /// report was created.
  void report({
    required int fill,
    required int underruns,
    required int received,
  }) {
    final estimate = fill + (_totalPushed - received);

    // A report that raced a reset() can briefly go negative.
    _estimatedFill = estimate < 0 ? 0 : estimate;
    _underruns += underruns;
  }

  void reset() {
    _estimatedFill = 0;
    _totalPushed = 0;
  }

  void resetStats() {
    _underruns = 0;
    _overruns = 0;
  }
}
