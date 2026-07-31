import 'dart:typed_data';

/// Per-channel capture buffers for the APU visualizer, pushed once per frame.
///
/// Only `[0, APU.sampleIndex)` is current. Entries past that are from earlier
/// frames and are never cleared. All five buffers share one length so a single
/// `sampleIndex` indexes every one of them.
///
/// Values are raw channel outputs, not normalized.
class ApuChannelSamples {
  ApuChannelSamples(int length)
    : pulse1 = Uint8List(length),
      pulse2 = Uint8List(length),
      triangle = Uint8List(length),
      noise = Uint8List(length),
      dmc = Uint8List(length);

  final Uint8List pulse1;
  final Uint8List pulse2;
  final Uint8List triangle;
  final Uint8List noise;
  final Uint8List dmc;

  /// Capacity of every buffer, so consumers can bounds-check instead of
  /// assuming agreement with `APU.sampleBuffer`.
  int get length => pulse1.length;
}
