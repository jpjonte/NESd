import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/channel/dmc_channel_state.dart';
import 'package:nesd/nes/apu/channel/noise_channel_state.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_state.dart';
import 'package:nesd/nes/apu/channel/triangle_channel_state.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';
import 'package:nesd/nes/serialization/nesd_uint64.dart';

class APUState {
  const APUState({
    required this.cycles,
    required this.sampleIndex,
    required this.sampleBuffer,
    required this.pulse1Samples,
    required this.pulse2Samples,
    required this.triangleSamples,
    required this.dmcSamples,
    required this.expansionSamples,
    required this.sampleStart,
    required this.frameCounterState,
    required this.pulse1State,
    required this.pulse2State,
    required this.triangleState,
    required this.noiseState,
    required this.dmcState,
  });

  factory APUState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => APUState._version0(reader),
      1 => APUState._version1(reader),
      2 => APUState._version2(reader),
      _ => throw InvalidSerializationVersion('APUState', version),
    };
  }

  factory APUState._version0(PayloadReader reader) {
    return APUState(
      cycles: reader.get(nesdUint64),
      sampleIndex: reader.get(nesdUint64),
      sampleBuffer: Float32List.fromList(reader.get(list(float32))),
      pulse1Samples: reader.get(nesdUint64),
      pulse2Samples: reader.get(nesdUint64),
      triangleSamples: reader.get(nesdUint64),
      dmcSamples: reader.get(nesdUint64),
      expansionSamples: 0,
      sampleStart: reader.get(nesdUint64),
      frameCounterState: FrameCounterState.deserialize(reader),
      pulse1State: PulseChannelState.deserialize(reader),
      pulse2State: PulseChannelState.deserialize(reader),
      triangleState: TriangleChannelState.deserialize(reader),
      noiseState: NoiseChannelState.deserialize(reader),
      dmcState: DMCChannelState.deserialize(reader),
    );
  }

  factory APUState._version1(PayloadReader reader) {
    return APUState(
      cycles: reader.get(nesdUint64),
      sampleIndex: reader.get(nesdUint64),
      sampleBuffer: reader.get(float32List(lengthType: uint32)),
      pulse1Samples: reader.get(nesdUint64),
      pulse2Samples: reader.get(nesdUint64),
      triangleSamples: reader.get(nesdUint64),
      dmcSamples: reader.get(nesdUint64),
      expansionSamples: 0,
      sampleStart: reader.get(nesdUint64),
      frameCounterState: FrameCounterState.deserialize(reader),
      pulse1State: PulseChannelState.deserialize(reader),
      pulse2State: PulseChannelState.deserialize(reader),
      triangleState: TriangleChannelState.deserialize(reader),
      noiseState: NoiseChannelState.deserialize(reader),
      dmcState: DMCChannelState.deserialize(reader),
    );
  }

  factory APUState._version2(PayloadReader reader) {
    return APUState(
      cycles: reader.get(nesdUint64),
      sampleIndex: reader.get(nesdUint64),
      sampleBuffer: reader.get(float32List(lengthType: uint32)),
      pulse1Samples: reader.get(nesdUint64),
      pulse2Samples: reader.get(nesdUint64),
      triangleSamples: reader.get(nesdUint64),
      dmcSamples: reader.get(nesdUint64),
      expansionSamples: reader.get(float64),
      sampleStart: reader.get(nesdUint64),
      frameCounterState: FrameCounterState.deserialize(reader),
      pulse1State: PulseChannelState.deserialize(reader),
      pulse2State: PulseChannelState.deserialize(reader),
      triangleState: TriangleChannelState.deserialize(reader),
      noiseState: NoiseChannelState.deserialize(reader),
      dmcState: DMCChannelState.deserialize(reader),
    );
  }

  final int cycles;

  final int sampleIndex;
  final Float32List sampleBuffer;

  final int pulse1Samples;
  final int pulse2Samples;
  final int triangleSamples;
  final int dmcSamples;
  final double expansionSamples;

  final int sampleStart;

  final FrameCounterState frameCounterState;

  final PulseChannelState pulse1State;
  final PulseChannelState pulse2State;

  final TriangleChannelState triangleState;

  final NoiseChannelState noiseState;

  final DMCChannelState dmcState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 2) // version
      ..set(nesdUint64, cycles)
      ..set(nesdUint64, sampleIndex)
      ..set(float32List(lengthType: uint32), sampleBuffer)
      ..set(nesdUint64, pulse1Samples)
      ..set(nesdUint64, pulse2Samples)
      ..set(nesdUint64, triangleSamples)
      ..set(nesdUint64, dmcSamples)
      ..set(float64, expansionSamples)
      ..set(nesdUint64, sampleStart);

    frameCounterState.serialize(writer);
    pulse1State.serialize(writer);
    pulse2State.serialize(writer);
    triangleState.serialize(writer);
    noiseState.serialize(writer);
    dmcState.serialize(writer);
  }
}
