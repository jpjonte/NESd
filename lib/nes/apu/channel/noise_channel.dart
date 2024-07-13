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

  int period = 0;

  int timerPeriod = 0;
  int timer = 0;

  int shiftRegister = 1;

  bool mode = false;

  NoiseChannelState get state => NoiseChannelState(
        enabled: enabled,
        constantVolume: constantVolume,
        volume: volume,
        period: period,
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
    period = state.period;
    timerPeriod = state.timerPeriod;
    timer = state.timer;
    shiftRegister = state.shiftRegister;
    mode = state.mode;
    envelope.state = state.envelopeState;
    lengthCounter.state = state.lengthCounterState;
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
  }

  int get status => lengthCounter.value > 0 ? 1 : 0;

  set status(int value) {
    enabled = value.bit(3) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }
  }

  void writeControl(int value) {
    lengthCounter.halt = value.bit(5) == 1;
    constantVolume = value.bit(4) == 1;
    volume = value & 0x0f;
    envelope
      ..loop = value.bit(5) == 1
      ..period = value & 0x0f
      ..start = true;
  }

  void writePeriod(int value) {
    mode = value.bit(7) == 1;
    period = noiseTable[value & 0x0f];
  }

  void writeLength(int value) {
    if (enabled) {
      lengthCounter.value = lengthCounterTable[value >> 3];
    }

    envelope.start = true;
  }

  void step() {
    if (timer > 0) {
      timer--;
    } else {
      timer = timerPeriod;

      final feedback = shiftRegister.bit(mode ? 6 : 1) ^ shiftRegister.bit(0);

      shiftRegister >>= 1;
      shiftRegister = shiftRegister.setBit(14, feedback);
    }
  }

  int get output {
    if (!enabled) {
      return 0;
    }

    if (lengthCounter.value == 0) {
      return 0;
    }

    if (shiftRegister.bit(0) == 1) {
      return 0;
    }

    return constantVolume ? volume : envelope.volume;
  }
}
