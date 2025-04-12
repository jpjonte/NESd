import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/apu_state.dart';
import 'package:nesd/nes/apu/channel/dmc_channel.dart';
import 'package:nesd/nes/apu/channel/noise_channel.dart';
import 'package:nesd/nes/apu/channel/pulse_channel.dart';
import 'package:nesd/nes/apu/channel/triangle_channel.dart';
import 'package:nesd/nes/apu/frame_counter/frame_counter.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/region.dart';

const ntscCpuFrequency = 1789773;
const palCpuFrequency = 1662607;

const apuSampleRate = 48000;

class APU {
  APU(this.bus);

  final Bus bus;

  int cycles = 0;

  int sampleIndex = 0;

  final sampleBuffer = Float32List(apuSampleRate * 5);

  final pulse1 = PulseChannel(onesComplement: true);
  final pulse2 = PulseChannel();

  final triangle = TriangleChannel();

  final noise = NoiseChannel();

  final dmc = DMCChannel();

  late final _frameCounter = FrameCounter(this);

  int _pulse1Samples = 0;
  int _pulse2Samples = 0;
  int _triangleSamples = 0;
  int _dmcSamples = 0;
  int _sampleStart = 0;

  double _cyclesPerSample = ntscCpuFrequency / apuSampleRate;

  APUState get state => APUState(
    cycles: cycles,
    sampleIndex: sampleIndex,
    sampleBuffer: sampleBuffer.sublist(0, sampleIndex),
    pulse1Samples: _pulse1Samples,
    pulse2Samples: _pulse2Samples,
    triangleSamples: _triangleSamples,
    dmcSamples: _dmcSamples,
    sampleStart: _sampleStart,
    frameCounterState: _frameCounter.state,
    pulse1State: pulse1.state,
    pulse2State: pulse2.state,
    triangleState: triangle.state,
    noiseState: noise.state,
    dmcState: dmc.state,
  );

  set state(APUState state) {
    cycles = state.cycles;

    sampleIndex = state.sampleIndex;

    sampleBuffer.setAll(0, state.sampleBuffer);

    _pulse1Samples = state.pulse1Samples;
    _pulse2Samples = state.pulse2Samples;
    _triangleSamples = state.triangleSamples;
    _dmcSamples = state.dmcSamples;
    _sampleStart = state.sampleStart;

    _frameCounter.state = state.frameCounterState;
    pulse1.state = state.pulse1State;
    pulse2.state = state.pulse2State;

    triangle.state = state.triangleState;
    noise.state = state.noiseState;
    dmc.state = state.dmcState;

    sampleIndex = 0;
  }

  // we don't need a getter from this
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    _frameCounter.region = region;

    switch (region) {
      case Region.ntsc:
        _cyclesPerSample = ntscCpuFrequency / apuSampleRate;
      case Region.pal:
        _cyclesPerSample = palCpuFrequency / apuSampleRate;
    }
  }

  int readRegister(int address, {bool disableSideEffects = false}) {
    if (address == 0x4015) {
      final status = 0
          .setBit(0, pulse1.status)
          .setBit(1, pulse2.status)
          .setBit(2, triangle.status)
          .setBit(3, noise.status)
          .setBit(4, dmc.status)
          .setBit(
            6,
            _frameCounter.getStatus(disableSideEffects: disableSideEffects),
          )
          .setBit(7, dmc.interruptStatus);

      return status;
    }

    return 0;
  }

  void writeRegister(int address, int value) {
    switch (address) {
      case 0x4000:
        pulse1.writeControl(value);
      case 0x4001:
        pulse1.writeSweep(value);
      case 0x4002:
        pulse1.writeTimerLow(value);
      case 0x4003:
        pulse1.writeTimerHigh(value);
      case 0x4004:
        pulse2.writeControl(value);
      case 0x4005:
        pulse2.writeSweep(value);
      case 0x4006:
        pulse2.writeTimerLow(value);
      case 0x4007:
        pulse2.writeTimerHigh(value);
      case 0x4008:
        triangle.writeControl(value);
      case 0x400a:
        triangle.writeTimerLow(value);
      case 0x400b:
        triangle.writeTimerHigh(value);
      case 0x400c:
        noise.writeControl(value);
      case 0x400e:
        noise.writePeriod(value);
      case 0x400f:
        noise.writeLength(value);
      case 0x4010:
        dmc.writeControl(value);
      case 0x4011:
        dmc.writeDirectLoad(value);
      case 0x4012:
        dmc.writeSampleAddress(value);
      case 0x4013:
        dmc.writeSampleLength(value);
      case 0x4015:
        _writeStatus(value);
      case 0x4017:
        _frameCounter.writeControl(value);
    }
  }

  void reset() {
    cycles = 0;

    sampleIndex = 0;

    _sampleStart = 0;

    _frameCounter.reset();

    pulse1.reset();
    pulse2.reset();
    triangle.reset();
    noise.reset();
    dmc.reset();
  }

  void step() {
    // triangle and DMC are stepped every CPU cycle
    triangle.step();
    dmc.step();

    if (cycles.isEven) {
      // other channels are stepped every other CPU cycle
      pulse1.step();
      pulse2.step();
      noise.step();

      _frameCounter.step();
    }

    if (dmc.startDma) {
      dmc.startDma = false;
      bus.triggerDmcDma();
    }

    if (dmc.interrupt) {
      bus.triggerIrq(IrqSource.apuDmc);
    } else {
      bus.clearIrq(IrqSource.apuDmc);
    }

    _handleSampling();

    cycles++;
  }

  void _writeStatus(int value) {
    pulse1.status = value;
    pulse2.status = value;
    triangle.status = value;
    noise.status = value;
    dmc.writeStatus(bus, value);
    bus.clearIrq(IrqSource.apuDmc);
  }

  void _handleSampling() {
    _gatherSamples();

    // if this cycle crossed the sample rate boundary, output a new sample
    final before = (cycles - 1) / _cyclesPerSample;
    final after = cycles / _cyclesPerSample;

    if (before.truncate() != after.truncate()) {
      sampleBuffer[sampleIndex++] = _output();
    }
  }

  void _gatherSamples() {
    _pulse1Samples += pulse1.output;
    _pulse2Samples += pulse2.output;
    _triangleSamples += triangle.output;
    _dmcSamples += dmc.output;
  }

  double _output() {
    final sampledCycles = cycles - _sampleStart;

    // average samples over the last [sampledCycles] cycles
    final pulse1Sample = (_pulse1Samples / sampledCycles).floor();
    final pulse2Sample = (_pulse2Samples / sampledCycles).floor();
    final pulseOut = pulseTable[pulse1Sample + pulse2Sample];

    final triangleSample = (_triangleSamples / sampledCycles).floor();
    final dmcSample = (_dmcSamples / sampledCycles).floor();

    final tndOut = tndTable[3 * triangleSample + 2 * noise.output + dmcSample];

    final mixed = pulseOut + tndOut;

    _sampleStart = cycles;
    _pulse1Samples = 0;
    _pulse2Samples = 0;
    _triangleSamples = 0;
    _dmcSamples = 0;

    return mixed;
  }
}
