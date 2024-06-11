import 'dart:typed_data';

import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/apu/channel/dmc_channel.dart';
import 'package:nes/nes/apu/channel/noise_channel.dart';
import 'package:nes/nes/apu/channel/pulse_channel.dart';
import 'package:nes/nes/apu/channel/triangle_channel.dart';
import 'package:nes/nes/apu/filter/filter.dart';
import 'package:nes/nes/apu/filter/filter_chain.dart';
import 'package:nes/nes/apu/frame_counter.dart';
import 'package:nes/nes/apu/tables.dart';
import 'package:nes/nes/bus.dart';

const apuSampleRate = 48000;

class APU {
  APU(this.bus);

  final Bus bus;

  int cycles = 0;

  int sampleIndex = 0;
  final sampleBuffer = Float32List(100000);

  late final frameCounter = FrameCounter(this);

  final pulse1 = PulseChannel(onesComplement: true);
  final pulse2 = PulseChannel();

  final triangle = TriangleChannel();

  final noise = NoiseChannel();

  final dmc = DMCChannel();

  final _filterChain = FilterChain([
    Filter.highPass(44100, 90),
    Filter.highPass(44100, 440),
    Filter.lowPass(44100, 14000),
  ]);

  int readRegister(int address) {
    if (address == 0x4015) {
      final status = 0
          .setBit(0, pulse1.status)
          .setBit(1, pulse2.status)
          .setBit(2, triangle.status)
          .setBit(3, noise.status)
          .setBit(4, dmc.status)
          .setBit(6, frameCounter.status)
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
        frameCounter.writeControl(value);
    }
  }

  void reset() {
    cycles = 0;

    sampleIndex = 0;

    frameCounter.reset();

    pulse1.reset();
    pulse2.reset();
    triangle.reset();
    noise.reset();
    dmc.reset();
  }

  void step() {
    // triangle is stepped every CPU cycle
    triangle.step();

    if (cycles.isEven) {
      // other channels are stepped every other CPU cycle
      _stepChannels();

      frameCounter.step();
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
  }

  void _stepChannels() {
    pulse1.step();
    pulse2.step();
    noise.step();
    dmc.step();

    if (dmc.startDma) {
      dmc.startDma = false;
      bus.cpu.dmcDma = true;
    }

    if (dmc.interrupt) {
      bus.cpu.irq = true;
    }
  }

  void _handleSampling() {
    // if this cycle crossed the sample rate boundary, output a new sample
    const cyclesPerSample =
        1779783 / apuSampleRate; // cpu frequency / audio sample rate
    final before = (cycles - 1) ~/ cyclesPerSample;
    final after = cycles ~/ cyclesPerSample;

    if (before != after) {
      sampleBuffer[sampleIndex++] = _output();
    }
  }

  double _output() {
    final pulseOut = pulseTable[pulse1.output + pulse2.output];
    final tndOut =
        tndTable[3 * triangle.output + 2 * noise.output + dmc.output];

    final output = pulseOut + tndOut;

    final filtered = _filterChain.apply(output);

    return filtered;
  }
}
