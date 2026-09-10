import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/expansion/expansion_audio.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio_state.dart';
import 'package:nesd/nes/apu/tables.dart';

class Sunsoft5BAudio implements ExpansionAudio {
  final Uint8List registers = Uint8List(16);

  int address = 0;

  bool writesDisabled = false;

  final _toneCounters = List.filled(3, 0);
  final _toneOutputs = List.filled(3, false);

  int _noiseCounter = 0;
  bool _noiseHalf = false;

  int noiseShift = 1;

  int _envelopeCounter = 0;
  int _envelopeStep = 0;

  bool _envelopeContinue = false;
  bool _envelopeAttack = false;
  bool _envelopeAlternate = false;
  bool _envelopeHold = false;

  bool _envelopeHolding = false;
  int _envelopeHoldLevel = 0;

  int _prescaler = 0;

  final List<int> _debugOutputs = List.filled(3, 0);

  Sunsoft5BAudioState get state => Sunsoft5BAudioState(
    registers: Uint8List.fromList(registers),
    address: address,
    writesDisabled: writesDisabled,
    toneCounters: List.of(_toneCounters),
    toneOutputs: List.of(_toneOutputs),
    noiseCounter: _noiseCounter,
    noiseHalf: _noiseHalf,
    noiseShift: noiseShift,
    envelopeCounter: _envelopeCounter,
    envelopeStep: _envelopeStep,
    envelopeContinue: _envelopeContinue,
    envelopeAttack: _envelopeAttack,
    envelopeAlternate: _envelopeAlternate,
    envelopeHold: _envelopeHold,
    envelopeHolding: _envelopeHolding,
    envelopeHoldLevel: _envelopeHoldLevel,
    prescaler: _prescaler,
  );

  set state(Sunsoft5BAudioState state) {
    registers.setAll(0, state.registers);

    address = state.address;
    writesDisabled = state.writesDisabled;

    _toneCounters.setAll(0, state.toneCounters);
    _toneOutputs.setAll(0, state.toneOutputs);

    _noiseCounter = state.noiseCounter;
    _noiseHalf = state.noiseHalf;
    noiseShift = state.noiseShift;

    _envelopeCounter = state.envelopeCounter;
    _envelopeStep = state.envelopeStep;

    _envelopeContinue = state.envelopeContinue;
    _envelopeAttack = state.envelopeAttack;
    _envelopeAlternate = state.envelopeAlternate;
    _envelopeHold = state.envelopeHold;

    _envelopeHolding = state.envelopeHolding;
    _envelopeHoldLevel = state.envelopeHoldLevel;

    _prescaler = state.prescaler;
  }

  @override
  ExpansionAudioKind get kind => ExpansionAudioKind.sunsoft5b;

  @override
  double get output =>
      sunsoft5bLevelTable[levelOf(0)] +
      sunsoft5bLevelTable[levelOf(1)] +
      sunsoft5bLevelTable[levelOf(2)];

  @override
  List<int> get debugOutputs {
    for (var i = 0; i < _debugOutputs.length; i++) {
      _debugOutputs[i] = levelOf(i);
    }

    return _debugOutputs;
  }

  int tonePeriodOf(int channel) {
    final base = channel * 2;
    final period = ((registers[base + 1] & 0x0f) << 8) | registers[base];

    return period == 0 ? 1 : period;
  }

  int get noisePeriod {
    final period = registers[0x06] & 0x1f;

    return period == 0 ? 1 : period;
  }

  int get envelopePeriod {
    final period = (registers[0x0c] << 8) | registers[0x0b];

    return period == 0 ? 1 : period;
  }

  int volumeOf(int channel) => registers[0x08 + channel] & 0x0f;

  bool usesEnvelope(int channel) => registers[0x08 + channel].bit(4) == 1;

  int get envelopeLevel => _envelopeHolding
      ? _envelopeHoldLevel
      : (_envelopeAttack ? _envelopeStep : 31 - _envelopeStep);

  int levelOf(int channel) {
    final toneEnabled = registers[0x07].bit(channel) == 0;
    final noiseEnabled = registers[0x07].bit(channel + 3) == 0;

    final active =
        (!toneEnabled || _toneOutputs[channel]) &&
        (!noiseEnabled || (noiseShift & 1) == 1);

    if (!active) {
      return 0;
    }

    if (usesEnvelope(channel)) {
      return envelopeLevel;
    }

    final volume = volumeOf(channel);

    return volume == 0 ? 0 : volume * 2 + 1;
  }

  void writeAddress(int value) {
    address = value & 0x0f;
    writesDisabled = (value & 0xf0) != 0;
  }

  void writeData(int value) {
    if (writesDisabled) {
      return;
    }

    registers[address] = value;

    if (address == 0x0d) {
      _restartEnvelope(value);
    }
  }

  void reset() {
    registers.fillRange(0, registers.length, 0);

    address = 0;
    writesDisabled = false;

    _toneCounters.fillRange(0, _toneCounters.length, 0);
    _toneOutputs.fillRange(0, _toneOutputs.length, false);

    _noiseCounter = 0;
    _noiseHalf = false;
    noiseShift = 1;

    _envelopeCounter = 0;
    _envelopeStep = 0;

    _envelopeContinue = false;
    _envelopeAttack = false;
    _envelopeAlternate = false;
    _envelopeHold = false;

    _envelopeHolding = false;
    _envelopeHoldLevel = 0;

    _prescaler = 0;
  }

  @override
  @pragma('vm:prefer-inline')
  void step() {
    if (++_prescaler < sunsoft5bPrescaler) {
      return;
    }

    _prescaler = 0;

    _stepTones();
    _stepNoise();
    _stepEnvelope();
  }

  void _stepTones() {
    for (var channel = 0; channel < 3; channel++) {
      if (++_toneCounters[channel] < tonePeriodOf(channel)) {
        continue;
      }

      _toneCounters[channel] = 0;
      _toneOutputs[channel] = !_toneOutputs[channel];
    }
  }

  void _stepNoise() {
    if (++_noiseCounter < noisePeriod) {
      return;
    }

    _noiseCounter = 0;
    _noiseHalf = !_noiseHalf;

    if (_noiseHalf) {
      return;
    }

    final feedback = (noiseShift ^ (noiseShift >> 3)) & 1;

    noiseShift = (noiseShift >> 1) | (feedback << 16);
  }

  void _stepEnvelope() {
    if (++_envelopeCounter < envelopePeriod) {
      return;
    }

    _envelopeCounter = 0;

    if (_envelopeHolding) {
      return;
    }

    if (++_envelopeStep <= 31) {
      return;
    }

    _envelopeStep = 0;

    if (!_envelopeContinue || _envelopeHold) {
      _envelopeHolding = true;
      _envelopeHoldLevel =
          _envelopeContinue && (_envelopeAttack != _envelopeAlternate) ? 31 : 0;

      return;
    }

    if (_envelopeAlternate) {
      _envelopeAttack = !_envelopeAttack;
    }
  }

  void _restartEnvelope(int shape) {
    _envelopeContinue = shape.bit(3) == 1;
    _envelopeAttack = shape.bit(2) == 1;
    _envelopeAlternate = shape.bit(1) == 1;
    _envelopeHold = shape.bit(0) == 1;

    _envelopeCounter = 0;
    _envelopeStep = 0;

    _envelopeHolding = false;
    _envelopeHoldLevel = 0;
  }
}
