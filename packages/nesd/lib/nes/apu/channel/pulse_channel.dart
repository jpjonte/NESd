import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_state.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/apu/unit/envelope_unit.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit.dart';
import 'package:nesd/nes/apu/unit/sweep_unit.dart';

class PulseChannel {
  PulseChannel({this.onesComplement = false});

  bool enabled = false;

  final bool onesComplement;

  final envelope = EnvelopeUnit();
  final lengthCounter = LengthCounterUnit();
  late final sweep = SweepUnit(this, onesComplement: onesComplement);

  int duty = 0;
  int _dutyMask = dutyCycleSequences[0];

  bool constantVolume = false;

  int volume = 0;

  int dutyIndex = 0;

  int timer = 0;
  int timerPeriod = 0;

  int output = 0;

  PulseChannelState get state => PulseChannelState(
    enabled: enabled,
    duty: duty,
    constantVolume: constantVolume,
    volume: volume,
    dutyIndex: dutyIndex,
    timer: timer,
    timerPeriod: timerPeriod,
    envelopeState: envelope.state,
    lengthCounterState: lengthCounter.state,
    sweepState: sweep.state,
  );

  set state(PulseChannelState state) {
    enabled = state.enabled;
    duty = state.duty;
    _dutyMask = dutyCycleSequences[duty];
    constantVolume = state.constantVolume;
    volume = state.volume;
    dutyIndex = state.dutyIndex;
    timer = state.timer;
    timerPeriod = state.timerPeriod;
    envelope.state = state.envelopeState;
    lengthCounter.state = state.lengthCounterState;
    sweep.state = state.sweepState;

    _updateOutput();
  }

  void reset() {
    enabled = false;
    duty = 0;
    _dutyMask = dutyCycleSequences[duty];
    constantVolume = false;
    volume = 0;

    lengthCounter.reset();
    envelope.reset();
    sweep.reset();

    _updateOutput();
  }

  int get status => lengthCounter.value > 0 ? 1 : 0;

  set status(int value) {
    enabled = value.bit(0) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }

    _updateOutput();
  }

  void writeControl(int value) {
    duty = (value >> 6) & 0x03;
    _dutyMask = dutyCycleSequences[duty];
    lengthCounter.halt = value.bit(5) == 1;
    constantVolume = value.bit(4) == 1;
    volume = value & 0x0f;
    envelope
      ..loop = value.bit(5) == 1
      ..period = value & 0x0f
      ..start = true;

    _updateOutput();
  }

  void writeSweep(int value) {
    sweep
      ..period = (value >> 4) & 0x07
      ..negate = value.bit(3) == 1
      ..shift = value & 0x07
      ..reload = true
      ..enabled = value.bit(7) == 1 && sweep.shift != 0;

    _updateOutput();
  }

  void writeTimerLow(int value) {
    timerPeriod = (timerPeriod & 0x700) | value;

    _updateOutput();
  }

  void writeTimerHigh(int value) {
    timerPeriod = (timerPeriod & 0xff) | ((value & 0x07) << 8);
    envelope.start = true;
    timer = timerPeriod;
    dutyIndex = 0;

    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }

    _updateOutput();
  }

  @pragma('vm:prefer-inline')
  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;
      dutyIndex = (dutyIndex - 1) & 7;

      _updateOutput();
    }
  }

  void clockEnvelope() {
    envelope.step();

    _updateOutput();
  }

  void clockLengthCounter() {
    lengthCounter.step();

    _updateOutput();
  }

  void clockSweep() {
    sweep.step();

    _updateOutput();
  }

  @pragma('vm:prefer-inline')
  void _updateOutput() {
    if (!enabled) {
      output = 0;

      return;
    }

    if (lengthCounter.value == 0) {
      output = 0;

      return;
    }

    if ((_dutyMask >> (7 - dutyIndex)) & 1 == 0) {
      output = 0;

      return;
    }

    if (sweep.muting) {
      output = 0;

      return;
    }

    output = constantVolume ? volume : envelope.volume;
  }
}
