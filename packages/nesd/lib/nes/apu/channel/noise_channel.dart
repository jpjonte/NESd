import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/noise_channel_state.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/apu/unit/envelope_unit.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit.dart';

class NoiseChannel {
  bool enabled = false;

  final envelope = EnvelopeUnit();
  final lengthCounter = LengthCounterUnit();

  bool constantVolume = false;
  int volume = 0;

  int timerPeriod = 0;
  int timer = 0;

  int shiftRegister = 1;

  bool mode = false;

  int output = 0;

  NoiseChannelState get state => NoiseChannelState(
    enabled: enabled,
    constantVolume: constantVolume,
    volume: volume,
    timerPeriod: timerPeriod,
    timer: timer,
    shiftRegister: shiftRegister,
    mode: mode,
    envelopeState: envelope.state,
    lengthCounterState: lengthCounter.state,
  );

  set state(NoiseChannelState state) {
    enabled = state.enabled;
    constantVolume = state.constantVolume;
    volume = state.volume;
    timerPeriod = state.timerPeriod;
    timer = state.timer;
    shiftRegister = state.shiftRegister;
    mode = state.mode;
    envelope.state = state.envelopeState;
    lengthCounter.state = state.lengthCounterState;

    _updateOutput();
  }

  void reset() {
    enabled = false;
    constantVolume = false;
    volume = 0;
    timer = 0;
    timerPeriod = 0;
    shiftRegister = 1;

    envelope.reset();
    lengthCounter.reset();

    _updateOutput();
  }

  int get status => lengthCounter.value > 0 ? 1 : 0;

  set status(int value) {
    enabled = value.bit(3) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }

    _updateOutput();
  }

  void writeControl(int value) {
    lengthCounter.halt = value.bit(5) == 1;
    constantVolume = value.bit(4) == 1;
    volume = value & 0x0f;
    envelope
      ..loop = value.bit(5) == 1
      ..period = value & 0x0f
      ..start = true;

    _updateOutput();
  }

  void writePeriod(int value) {
    mode = value.bit(7) == 1;
    timerPeriod = noiseTable[value & 0x0f] - 1;

    _updateOutput();
  }

  void writeLength(int value) {
    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }

    envelope.start = true;

    _updateOutput();
  }

  void clockEnvelope() {
    envelope.step();

    _updateOutput();
  }

  void clockLengthCounter() {
    lengthCounter.step();

    _updateOutput();
  }

  @pragma('vm:prefer-inline')
  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;

      final feedback = shiftRegister.bit(mode ? 6 : 1) ^ shiftRegister.bit(0);

      shiftRegister >>= 1;
      shiftRegister = shiftRegister.setBit(14, feedback);

      _updateOutput();
    }
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

    if (shiftRegister.bit(0) == 1) {
      output = 0;

      return;
    }

    output = constantVolume ? volume : envelope.volume;
  }
}
