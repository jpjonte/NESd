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

  bool constantVolume = false;

  int volume = 0;

  int dutyIndex = 0;

  int timer = 0;
  int timerPeriod = 0;

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
    constantVolume = state.constantVolume;
    volume = state.volume;
    dutyIndex = state.dutyIndex;
    timer = state.timer;
    timerPeriod = state.timerPeriod;
    envelope.state = state.envelopeState;
    lengthCounter.state = state.lengthCounterState;
    sweep.state = state.sweepState;
  }

  void reset() {
    enabled = false;
    duty = 0;
    constantVolume = false;
    volume = 0;

    lengthCounter.reset();
    envelope.reset();
    sweep.reset();
  }

  int get status => lengthCounter.value > 0 ? 1 : 0;

  set status(int value) {
    enabled = value.bit(0) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }
  }

  void writeControl(int value) {
    duty = (value >> 6) & 0x03;
    lengthCounter.halt = value.bit(5) == 1;
    constantVolume = value.bit(4) == 1;
    volume = value & 0x0f;
    envelope
      ..loop = value.bit(5) == 1
      ..period = value & 0x0f
      ..start = true;
  }

  void writeSweep(int value) {
    sweep
      ..period = (value >> 4) & 0x07
      ..negate = value.bit(3) == 1
      ..shift = value & 0x07
      ..reload = true
      ..enabled = value.bit(7) == 1 && sweep.shift != 0;
  }

  void writeTimerLow(int value) {
    timerPeriod = (timerPeriod & 0x700) | value;
  }

  void writeTimerHigh(int value) {
    timerPeriod = (timerPeriod & 0xff) | ((value & 0x07) << 8);
    envelope.start = true;
    timer = timerPeriod;
    dutyIndex = 0;

    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }
  }

  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;
      dutyIndex = (dutyIndex - 1) & 7;
    }
  }

  int get output {
    if (!enabled) {
      return 0;
    }

    if (lengthCounter.value == 0) {
      return 0;
    }

    if (dutyCycleSequences[duty].bit(7 - dutyIndex) == 0) {
      return 0;
    }

    if (sweep.muting) {
      return 0;
    }

    return constantVolume ? volume : envelope.volume;
  }
}
