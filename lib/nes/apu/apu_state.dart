import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nes/nes/apu/channel/dmc_channel_state.dart';
import 'package:nes/nes/apu/channel/noise_channel_state.dart';
import 'package:nes/nes/apu/channel/pulse_channel_state.dart';
import 'package:nes/nes/apu/channel/triangle_channel_state.dart';
import 'package:nes/nes/apu/frame_counter/frame_counter_state.dart';

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
}

class _APUStateContract extends BinaryContract<APUState> implements APUState {
  _APUStateContract() : super(APUState.dummy());

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
        frameCounterStateContract,
        (o) => o.frameCounterState,
      );

  @override
  PulseChannelState get pulse1State => type(
        pulseChannelStateContract,
        (o) => o.pulse1State,
      );

  @override
  PulseChannelState get pulse2State => type(
        pulseChannelStateContract,
        (o) => o.pulse2State,
      );

  @override
  TriangleChannelState get triangleState => type(
        triangleChannelStateContract,
        (o) => o.triangleState,
      );

  @override
  NoiseChannelState get noiseState => type(
        noiseChannelStateContract,
        (o) => o.noiseState,
      );

  @override
  DMCChannelState get dmcState => type(
        dmcChannelStateContract,
        (o) => o.dmcState,
      );
}

final apuStateContract = _APUStateContract();
