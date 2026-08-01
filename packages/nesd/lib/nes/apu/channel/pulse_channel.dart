import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_core.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_state.dart';
import 'package:nesd/nes/apu/unit/sweep_unit.dart';

class PulseChannel extends PulseChannelCore {
  PulseChannel({this.onesComplement = false, this.statusBit = 0});

  final bool onesComplement;

  /// This channel's enable bit in `$4015`.
  final int statusBit;

  late final sweep = SweepUnit(this, onesComplement: onesComplement);

  @override
  bool get muted => sweep.muting;

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

    updateOutput();
  }

  @override
  void reset() {
    super.reset();

    sweep.reset();
  }

  set status(int value) {
    enabled = value.bit(statusBit) == 1;

    if (!enabled) {
      lengthCounter.value = 0;
    }

    updateOutput();
  }

  void writeSweep(int value) {
    sweep
      ..period = (value >> 4) & 0x07
      ..negate = value.bit(3) == 1
      ..shift = value & 0x07
      ..reload = true
      ..enabled = value.bit(7) == 1 && sweep.shift != 0;

    updateOutput();
  }

  void clockSweep() {
    sweep.step();

    updateOutput();
  }
}
