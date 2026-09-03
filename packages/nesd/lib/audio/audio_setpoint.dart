import 'dart:math';

/// The pacing setpoint every native platform starts with: 25 ms at the APU
/// sample rate.
const defaultAudioSetpointSamples = 1200;

/// Setpoint for a device whose largest single read is [popMax] samples.
int audioSetpointFor({required int popMax, required int capacity}) =>
    max(defaultAudioSetpointSamples, min(capacity ~/ 2, popMax * 5 ~/ 2));
