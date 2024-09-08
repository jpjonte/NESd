import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/channel/dmc_channel_state.dart';
import 'package:nesd/nes/apu/channel/noise_channel_state.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_state.dart';
import 'package:nesd/nes/apu/channel/triangle_channel_state.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter_state.dart';

class APUState {
  const APUState({
    required this.cycles,
    required this.sampleIndex,
    required this.sampleBuffer,
    required this.pulse1Samples,
    required this.pulse2Samples,
    required this.triangleSamples,
    required this.dmcSamples,
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
      _ => throw InvalidSerializationVersion('APUState', version),
    };
  }

  factory APUState._version0(PayloadReader reader) {
    return APUState(
      cycles: reader.get(uint64),
      sampleIndex: reader.get(uint64),
      sampleBuffer: Float32List.fromList(reader.get(list(float32))),
      pulse1Samples: reader.get(uint64),
      pulse2Samples: reader.get(uint64),
      triangleSamples: reader.get(uint64),
      dmcSamples: reader.get(uint64),
      sampleStart: reader.get(uint64),
      frameCounterState: FrameCounterState.deserialize(reader),
      pulse1State: PulseChannelState.deserialize(reader),
      pulse2State: PulseChannelState.deserialize(reader),
      triangleState: TriangleChannelState.deserialize(reader),
      noiseState: NoiseChannelState.deserialize(reader),
      dmcState: DMCChannelState.deserialize(reader),
    );
  }

  APUState.dummy()
      : this(
          cycles: 0,
          sampleIndex: 0,
          sampleBuffer: Float32List(0),
          pulse1Samples: 0,
          pulse2Samples: 0,
          triangleSamples: 0,
          dmcSamples: 0,
          sampleStart: 0,
          frameCounterState: const FrameCounterState.dummy(),
          pulse1State: const PulseChannelState.dummy(),
          pulse2State: const PulseChannelState.dummy(),
          triangleState: const TriangleChannelState.dummy(),
          noiseState: const NoiseChannelState.dummy(),
          dmcState: const DMCChannelState.dummy(),
        );

  final int cycles;

  final int sampleIndex;
  final Float32List sampleBuffer;

  final int pulse1Samples;
  final int pulse2Samples;
  final int triangleSamples;
  final int dmcSamples;
  final int sampleStart;

  final FrameCounterState frameCounterState;

  final PulseChannelState pulse1State;
  final PulseChannelState pulse2State;

  final TriangleChannelState triangleState;

  final NoiseChannelState noiseState;

  final DMCChannelState dmcState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint64, cycles)
      ..set(uint64, sampleIndex)
      ..set(list(float32), sampleBuffer)
      ..set(uint64, pulse1Samples)
      ..set(uint64, pulse2Samples)
      ..set(uint64, triangleSamples)
      ..set(uint64, dmcSamples)
      ..set(uint64, sampleStart);

    frameCounterState.serialize(writer);
    pulse1State.serialize(writer);
    pulse2State.serialize(writer);
    triangleState.serialize(writer);
    noiseState.serialize(writer);
    dmcState.serialize(writer);
  }
}

class _LegacyAPUStateContract extends BinaryContract<APUState>
    implements APUState {
  _LegacyAPUStateContract() : super(APUState.dummy());

  @override
  APUState order(APUState contract) {
    return APUState(
      cycles: contract.cycles,
      sampleIndex: contract.sampleIndex,
      sampleBuffer: contract.sampleBuffer,
      pulse1Samples: contract.pulse1Samples,
      pulse2Samples: contract.pulse2Samples,
      triangleSamples: contract.triangleSamples,
      dmcSamples: contract.dmcSamples,
      sampleStart: contract.sampleStart,
      frameCounterState: contract.frameCounterState,
      pulse1State: contract.pulse1State,
      pulse2State: contract.pulse2State,
      triangleState: contract.triangleState,
      noiseState: contract.noiseState,
      dmcState: contract.dmcState,
    );
  }

  @override
  int get cycles => type(uint64, (o) => o.cycles);

  @override
  int get sampleIndex => type(uint64, (o) => o.sampleIndex);

  @override
  Float32List get sampleBuffer => Float32List.fromList(
        type(list(float32), (o) => o.sampleBuffer),
      );

  @override
  int get pulse1Samples => type(uint64, (o) => o.pulse1Samples);

  @override
  int get pulse2Samples => type(uint64, (o) => o.pulse2Samples);

  @override
  int get triangleSamples => type(uint64, (o) => o.triangleSamples);

  @override
  int get dmcSamples => type(uint64, (o) => o.dmcSamples);

  @override
  int get sampleStart => type(uint64, (o) => o.sampleStart);

  @override
  FrameCounterState get frameCounterState => type(
        legacyFrameCounterStateContract,
        (o) => o.frameCounterState,
      );

  @override
  PulseChannelState get pulse1State => type(
        legacyPulseChannelStateContract,
        (o) => o.pulse1State,
      );

  @override
  PulseChannelState get pulse2State => type(
        legacyPulseChannelStateContract,
        (o) => o.pulse2State,
      );

  @override
  TriangleChannelState get triangleState => type(
        legacyTriangleChannelStateContract,
        (o) => o.triangleState,
      );

  @override
  NoiseChannelState get noiseState => type(
        legacyNoiseChannelStateContract,
        (o) => o.noiseState,
      );

  @override
  DMCChannelState get dmcState => type(
        legacyDmcChannelStateContract,
        (o) => o.dmcState,
      );

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

final legacyApuStateContract = _LegacyAPUStateContract();
