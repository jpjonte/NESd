import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/apu/unit/envelope_unit.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit.dart';

abstract class PulseChannelCore {
  bool enabled = false;

  final envelope = EnvelopeUnit();
  final lengthCounter = LengthCounterUnit();

  int _duty = 0;
  int _dutyMask = dutyCycleSequences[0];

  int get duty => _duty;

  set duty(int value) {
    _duty = value;
    _dutyMask = dutyCycleSequences[value];
  }

  bool constantVolume = false;

  int volume = 0;

  int dutyIndex = 0;

  int timer = 0;
  int timerPeriod = 0;

  int output = 0;

  int get status => lengthCounter.value > 0 ? 1 : 0;

  /// Whether a sweep unit is muting the channel. Overridable by subclasses.
  bool get muted => false;

  void reset() {
    enabled = false;
    duty = 0;
    constantVolume = false;
    volume = 0;

    lengthCounter.reset();
    envelope.reset();

    updateOutput();
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

    updateOutput();
  }

  void writeTimerLow(int value) {
    timerPeriod = (timerPeriod & 0x700) | value;

    updateOutput();
  }

  void writeTimerHigh(int value) {
    timerPeriod = (timerPeriod & 0xff) | ((value & 0x07) << 8);
    envelope.start = true;
    timer = timerPeriod;
    dutyIndex = 0;

    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }

    updateOutput();
  }

  @pragma('vm:prefer-inline')
  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;
      dutyIndex = (dutyIndex - 1) & 7;

      updateOutput();
    }
  }

  void clockEnvelope() {
    envelope.step();

    updateOutput();
  }

  void clockLengthCounter() {
    lengthCounter.step();

    updateOutput();
  }

  /// Recomputes [output] from the current channel state.
  ///
  /// Not part of the public API, but needs to be triggerable by subclasses.
  @pragma('vm:prefer-inline')
  void updateOutput() {
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

    if (muted) {
      output = 0;

      return;
    }

    output = constantVolume ? volume : envelope.volume;
  }
}
