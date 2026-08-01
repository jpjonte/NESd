import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/apu/channel/pulse_channel_core.dart';
import 'package:nesd/nes/apu/expansion/expansion_audio.dart';
import 'package:nesd/nes/apu/tables.dart';

class Mmc5Audio implements ExpansionAudio {
  final pulse1 = Mmc5Pulse();
  final pulse2 = Mmc5Pulse();

  int cycles = 0;

  int sequencerTimer = mmc5SequencerPeriod;

  final List<int> _debugOutputs = List.filled(3, 0);

  @override
  double get output => (pulse1.output + pulse2.output) * mmc5PulseScale;

  @override
  List<int> get debugOutputs => _debugOutputs
    ..[0] = pulse1.output
    ..[1] = pulse2.output
    ..[2] = 0;

  void reset() {
    cycles = 0;
    sequencerTimer = mmc5SequencerPeriod;

    pulse1.reset();
    pulse2.reset();
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
      case 0x5015:
        _writeStatus(value);
    }
  }

  int readRegister(int address, {bool disableSideEffects = false}) {
    if (address == 0x5015) {
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
}

/// One MMC5 pulse channel: [PulseChannelCore] with no sweep unit.
class Mmc5Pulse extends PulseChannelCore {
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
