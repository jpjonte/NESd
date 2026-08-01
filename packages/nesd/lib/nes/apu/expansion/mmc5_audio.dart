import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_core.dart';
import 'package:nesd/nes/apu/expansion/expansion_audio.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio_state.dart';
import 'package:nesd/nes/apu/tables.dart';

class Mmc5Audio implements ExpansionAudio {
  final pulse1 = Mmc5Pulse();
  final pulse2 = Mmc5Pulse();

  int cycles = 0;

  int sequencerTimer = mmc5SequencerPeriod;

  final List<int> _debugOutputs = List.filled(3, 0);

  int pcmLevel = 0;

  /// Read mode is not emulated: no known game uses it, so the bit is stored and
  /// makes `$5011` inert.
  bool pcmReadMode = false;

  bool pcmIrqEnabled = false;
  bool pcmIrqPending = false;

  bool get pcmIrqAsserted => pcmIrqEnabled && pcmIrqPending;

  Mmc5AudioState get state => Mmc5AudioState(
    pulse1State: pulse1.state,
    pulse2State: pulse2.state,
    cycles: cycles,
    sequencerTimer: sequencerTimer,
    pcmLevel: pcmLevel,
    pcmReadMode: pcmReadMode,
    pcmIrqEnabled: pcmIrqEnabled,
    pcmIrqPending: pcmIrqPending,
  );

  set state(Mmc5AudioState state) {
    pulse1.state = state.pulse1State;
    pulse2.state = state.pulse2State;

    cycles = state.cycles;
    sequencerTimer = state.sequencerTimer;

    pcmLevel = state.pcmLevel;
    pcmReadMode = state.pcmReadMode;
    pcmIrqEnabled = state.pcmIrqEnabled;
    pcmIrqPending = state.pcmIrqPending;
  }

  @override
  double get output =>
      (pulse1.output + pulse2.output) * mmc5PulseScale +
      pcmLevel * mmc5PcmScale;

  @override
  List<int> get debugOutputs => _debugOutputs
    ..[0] = pulse1.output
    ..[1] = pulse2.output
    ..[2] = pcmLevel;

  void reset() {
    cycles = 0;
    sequencerTimer = mmc5SequencerPeriod;

    pulse1.reset();
    pulse2.reset();

    pcmLevel = 0;
    pcmReadMode = false;
    pcmIrqEnabled = false;
    pcmIrqPending = false;
  }

  @override
  @pragma('vm:prefer-inline')
  void step() {
    if (cycles.isEven) {
      pulse1.step();
      pulse2.step();

      _stepSequencer();
    }

    cycles++;
  }

  void writeRegister(int address, int value) {
    switch (address) {
      case 0x5000:
        pulse1.writeControl(value);
      case 0x5002:
        pulse1.writeTimerLow(value);
      case 0x5003:
        pulse1.writeTimerHigh(value);
      case 0x5004:
        pulse2.writeControl(value);
      case 0x5006:
        pulse2.writeTimerLow(value);
      case 0x5007:
        pulse2.writeTimerHigh(value);
      case 0x5010:
        pcmIrqEnabled = value.bit(7) == 1;
        pcmReadMode = value.bit(0) == 1;
      case 0x5011:
        _writePcmData(value);
      case 0x5015:
        _writeStatus(value);
    }
  }

  int readRegister(int address, {bool disableSideEffects = false}) {
    switch (address) {
      case 0x5010:
        final result = pcmIrqPending ? 0x80 : 0x00;

        if (!disableSideEffects) {
          pcmIrqPending = false;
        }

        return result;
      case 0x5015:
        return pulse1.status | (pulse2.status << 1);
    }

    return 0;
  }

  void _writeStatus(int value) {
    pulse1.enable = value.bit(0) == 1;
    pulse2.enable = value.bit(1) == 1;
  }

  @pragma('vm:prefer-inline')
  void _stepSequencer() {
    if (sequencerTimer > 0) {
      sequencerTimer--;

      return;
    }

    sequencerTimer = mmc5SequencerPeriod;

    pulse1
      ..clockEnvelope()
      ..clockLengthCounter();

    pulse2
      ..clockEnvelope()
      ..clockLengthCounter();
  }

  void _writePcmData(int value) {
    if (pcmReadMode) {
      return;
    }

    if (value == 0) {
      pcmIrqPending = true;

      return;
    }

    pcmIrqPending = false;
    pcmLevel = value;
  }
}

/// One MMC5 pulse channel: [PulseChannelCore] with no sweep unit.
class Mmc5Pulse extends PulseChannelCore {
  Mmc5PulseState get state => Mmc5PulseState(
    enabled: enabled,
    duty: duty,
    constantVolume: constantVolume,
    volume: volume,
    dutyIndex: dutyIndex,
    timer: timer,
    timerPeriod: timerPeriod,
    envelopeState: envelope.state,
    lengthCounterState: lengthCounter.state,
  );

  set state(Mmc5PulseState state) {
    enabled = state.enabled;
    duty = state.duty;
    constantVolume = state.constantVolume;
    volume = state.volume;
    dutyIndex = state.dutyIndex;
    timer = state.timer;
    timerPeriod = state.timerPeriod;
    envelope.state = state.envelopeState;
    lengthCounter.state = state.lengthCounterState;

    updateOutput();
  }

  // we don't need a getter, `enabled` is public
  // ignore: avoid_setters_without_getters
  set enable(bool value) {
    enabled = value;

    if (!enabled) {
      lengthCounter.value = 0;
    }

    updateOutput();
  }
}
