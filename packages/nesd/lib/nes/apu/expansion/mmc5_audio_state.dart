import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/apu/unit/envelope_unit_state.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

/// One MMC5 pulse channel's state. Unlike `PulseChannelState` there is
/// no sweep unit: the MMC5 has none.
class Mmc5PulseState {
  const Mmc5PulseState({
    required this.enabled,
    required this.duty,
    required this.constantVolume,
    required this.volume,
    required this.dutyIndex,
    required this.timer,
    required this.timerPeriod,
    required this.envelopeState,
    required this.lengthCounterState,
  });

  const Mmc5PulseState.initial()
    : enabled = false,
      duty = 0,
      constantVolume = false,
      volume = 0,
      dutyIndex = 0,
      timer = 0,
      timerPeriod = 0,
      envelopeState = const EnvelopeUnitState(
        volume: 0,
        period: 0,
        timer: 0,
        start: false,
        loop: false,
      ),
      lengthCounterState = const LengthCounterUnitState(halt: false, value: 0);

  factory Mmc5PulseState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Mmc5PulseState._version0(reader),
      _ => throw InvalidSerializationVersion('Mmc5PulseState', version),
    };
  }

  factory Mmc5PulseState._version0(PayloadReader reader) {
    return Mmc5PulseState(
      enabled: reader.get(boolean),
      duty: reader.get(uint8),
      constantVolume: reader.get(boolean),
      volume: reader.get(uint8),
      dutyIndex: reader.get(uint8),
      timer: reader.get(uint16),
      timerPeriod: reader.get(uint16),
      envelopeState: EnvelopeUnitState.deserialize(reader),
      lengthCounterState: LengthCounterUnitState.deserialize(reader),
    );
  }

  final bool enabled;
  final int duty;
  final bool constantVolume;
  final int volume;
  final int dutyIndex;
  final int timer;
  final int timerPeriod;

  final EnvelopeUnitState envelopeState;
  final LengthCounterUnitState lengthCounterState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(boolean, enabled)
      ..set(uint8, duty)
      ..set(boolean, constantVolume)
      ..set(uint8, volume)
      ..set(uint8, dutyIndex)
      ..set(uint16, timer)
      ..set(uint16, timerPeriod);

    envelopeState.serialize(writer);
    lengthCounterState.serialize(writer);
  }
}

class Mmc5AudioState {
  const Mmc5AudioState({
    required this.pulse1State,
    required this.pulse2State,
    required this.cycles,
    required this.sequencerTimer,
    required this.pcmLevel,
    required this.pcmReadMode,
    required this.pcmIrqEnabled,
    required this.pcmIrqPending,
  });

  /// The state of a chip that has never been written: silent. This is
  /// what `MMC5State` version 0 and 1 restore.
  const Mmc5AudioState.initial()
    : pulse1State = const Mmc5PulseState.initial(),
      pulse2State = const Mmc5PulseState.initial(),
      cycles = 0,
      sequencerTimer = mmc5SequencerPeriod,
      pcmLevel = 0,
      pcmReadMode = false,
      pcmIrqEnabled = false,
      pcmIrqPending = false;

  factory Mmc5AudioState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Mmc5AudioState._version0(reader),
      _ => throw InvalidSerializationVersion('Mmc5AudioState', version),
    };
  }

  factory Mmc5AudioState._version0(PayloadReader reader) {
    return Mmc5AudioState(
      pulse1State: Mmc5PulseState.deserialize(reader),
      pulse2State: Mmc5PulseState.deserialize(reader),
      cycles: reader.get(uint64),
      sequencerTimer: reader.get(uint16),
      pcmLevel: reader.get(uint8),
      pcmReadMode: reader.get(boolean),
      pcmIrqEnabled: reader.get(boolean),
      pcmIrqPending: reader.get(boolean),
    );
  }

  final Mmc5PulseState pulse1State;
  final Mmc5PulseState pulse2State;

  final int cycles;
  final int sequencerTimer;

  final int pcmLevel;
  final bool pcmReadMode;
  final bool pcmIrqEnabled;
  final bool pcmIrqPending;

  void serialize(PayloadWriter writer) {
    writer.set(uint8, 0); // version

    pulse1State.serialize(writer);
    pulse2State.serialize(writer);

    writer
      ..set(uint64, cycles)
      ..set(uint16, sequencerTimer)
      ..set(uint8, pcmLevel)
      ..set(boolean, pcmReadMode)
      ..set(boolean, pcmIrqEnabled)
      ..set(boolean, pcmIrqPending);
  }
}
