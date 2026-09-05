import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio.dart';
import 'package:nesd/nes/apu/tables.dart';

void main() {
  late Mmc5Audio audio;

  setUp(() => audio = Mmc5Audio());

  void runApuCycles(int count) {
    // 1 APU cycle == 2 CPU cycles
    for (var i = 0; i < count * 2; i++) {
      audio.step();
    }
  }

  /// Enables pulse 1 at duty 3, constant volume 15, and loads a length of 2.
  /// Duty 3 is `0xfc`, whose bit 7 is set, so the channel is audible at duty
  /// index 0 without stepping.
  void enableAudiblePulse1() {
    audio
      ..writeRegister(0x5015, 0x01)
      ..writeRegister(0x5000, 0xdf)
      ..writeRegister(0x5003, 0x18);
  }

  group('registers', () {
    test(r'$5000 sets duty, halt, constant volume and volume', () {
      audio.writeRegister(0x5000, 0xbf);

      expect(audio.pulse1.duty, 2);
      expect(audio.pulse1.lengthCounter.halt, true);
      expect(audio.pulse1.constantVolume, true);
      expect(audio.pulse1.volume, 0x0f);
    });

    test(r'$5002 and $5003 assemble the 11-bit timer period', () {
      audio
        ..writeRegister(0x5002, 0x34)
        ..writeRegister(0x5003, 0x02);

      expect(audio.pulse1.timerPeriod, 0x234);
    });

    test(r'$5004 addresses pulse 2, leaving pulse 1 alone', () {
      audio.writeRegister(0x5004, 0xbf);

      expect(audio.pulse2.duty, 2);
      expect(audio.pulse1.duty, 0);
    });

    test(r'$5001 is inert: the MMC5 has no sweep unit', () {
      enableAudiblePulse1();

      final before = audio.output;

      audio.writeRegister(0x5001, 0xff);

      expect(audio.output, before);
      expect(audio.pulse1.timerPeriod, 0);
    });

    test('a timer period below 8 is not muted', () {
      // The APU mutes periods below 8 inside its sweep unit. With no
      // sweep unit there is nothing to mute the channel.
      enableAudiblePulse1();

      audio.writeRegister(0x5002, 0x02);

      expect(audio.pulse1.timerPeriod, 2);
      expect(audio.output, greaterThan(0));
    });
  });

  group(r'$5015', () {
    test('bit 0 enables pulse 1 and bit 1 enables pulse 2', () {
      audio.writeRegister(0x5015, 0x02);

      expect(audio.pulse1.enabled, false);
      expect(audio.pulse2.enabled, true);
    });

    test('clearing an enable bit zeroes that length counter', () {
      enableAudiblePulse1();

      expect(audio.pulse1.lengthCounter.value, 2);

      audio.writeRegister(0x5015, 0x00);

      expect(audio.pulse1.lengthCounter.value, 0);
      expect(audio.output, 0);
    });
  });

  group('timing', () {
    test('the sequencer divider is 3728 APU cycles (240 Hz)', () {
      expect(mmc5SequencerPeriod, 3728);
    });

    test('the timer advances once per two CPU cycles', () {
      enableAudiblePulse1();

      audio.step();

      expect(audio.pulse1.dutyIndex, 7);

      audio.step();

      expect(audio.pulse1.dutyIndex, 7);

      audio.step();

      expect(audio.pulse1.dutyIndex, 6);
    });

    test('the sequencer clocks envelope and length together', () {
      audio
        ..writeRegister(0x5015, 0x01)
        // duty 3, no halt, envelope mode, envelope period 15
        ..writeRegister(0x5000, 0xcf)
        ..writeRegister(0x5003, 0x18);

      expect(audio.pulse1.lengthCounter.value, 2);

      runApuCycles(mmc5SequencerPeriod + 1);

      // One sequencer step: the envelope started, and the length counter
      // ticked. The APU splits these across 240/120 Hz. The MMC5 does both at
      // 240 Hz.
      expect(audio.pulse1.envelope.volume, 15);
      expect(audio.pulse1.lengthCounter.value, 1);

      runApuCycles(mmc5SequencerPeriod + 1);

      expect(audio.pulse1.lengthCounter.value, 0);
      expect(audio.output, 0);
    });
  });

  group('output', () {
    test('a silent chip outputs zero', () {
      expect(audio.output, 0);
    });

    test('both pulses at full volume peak at the internal pulse peak', () {
      audio
        ..writeRegister(0x5015, 0x03)
        ..writeRegister(0x5000, 0xdf)
        ..writeRegister(0x5003, 0x18)
        ..writeRegister(0x5004, 0xdf)
        ..writeRegister(0x5007, 0x18);

      expect(audio.pulse1.output, 15);
      expect(audio.pulse2.output, 15);
      expect(audio.output, closeTo(pulseTable[30], 1e-12));
    });

    test('debugOutputs reports the two pulses and the PCM level', () {
      enableAudiblePulse1();

      expect(audio.debugOutputs, [15, 0, 0]);
    });

    test('debugOutputs reuses its backing list', () {
      // Read once per emitted sample while the panel is open, so it must not
      // allocate.
      expect(identical(audio.debugOutputs, audio.debugOutputs), true);
    });
  });

  group('reset', () {
    test('reset() silences both pulses', () {
      audio
        ..writeRegister(0x5015, 0x03)
        ..writeRegister(0x5000, 0xdf)
        ..writeRegister(0x5003, 0x18)
        ..writeRegister(0x5004, 0xdf)
        ..writeRegister(0x5007, 0x18);

      expect(audio.output, greaterThan(0));

      audio.reset();

      expect(audio.pulse1.enabled, false);
      expect(audio.pulse2.enabled, false);
      expect(audio.output, 0);
    });
  });

  group('PCM', () {
    test(r'$5011 sets the output level', () {
      audio.writeRegister(0x5011, 0x80);

      expect(audio.pcmLevel, 0x80);
      expect(audio.output, closeTo(0x80 * mmc5PcmScale, 1e-12));
    });

    test('full-scale PCM sits at DMC full-scale amplitude', () {
      audio.writeRegister(0x5011, 0xff);

      expect(audio.output, closeTo(tndTable[127], 1e-9));
    });

    test('writing zero keeps the level and raises the IRQ flag', () {
      audio
        ..writeRegister(0x5011, 0x40)
        ..writeRegister(0x5011, 0x00);

      expect(audio.pcmLevel, 0x40);
      expect(audio.pcmIrqPending, true);
    });

    test('a non-zero write clears the IRQ flag', () {
      audio
        ..writeRegister(0x5011, 0x00)
        ..writeRegister(0x5011, 0x40);

      expect(audio.pcmIrqPending, false);
    });

    test(r'$5010 bit 7 enables the IRQ, bit 0 selects read mode', () {
      audio.writeRegister(0x5010, 0x81);

      expect(audio.pcmIrqEnabled, true);
      expect(audio.pcmReadMode, true);
    });

    test('the IRQ is only asserted while enabled', () {
      audio.writeRegister(0x5011, 0x00);

      expect(audio.pcmIrqPending, true);
      expect(audio.pcmIrqAsserted, false);

      audio.writeRegister(0x5010, 0x80);

      expect(audio.pcmIrqAsserted, true);
    });

    test(r'reading $5010 returns the flag in bit 7 and acknowledges', () {
      audio
        ..writeRegister(0x5010, 0x80)
        ..writeRegister(0x5011, 0x00);

      expect(audio.readRegister(0x5010), 0x80);
      expect(audio.pcmIrqPending, false);
      expect(audio.readRegister(0x5010), 0x00);
    });

    test(r'reading $5010 with side effects disabled does not acknowledge', () {
      audio
        ..writeRegister(0x5010, 0x80)
        ..writeRegister(0x5011, 0x00);

      expect(audio.readRegister(0x5010, disableSideEffects: true), 0x80);
      expect(audio.pcmIrqPending, true);
    });

    test(r'read mode makes $5011 inert', () {
      audio
        ..writeRegister(0x5011, 0x40)
        ..writeRegister(0x5010, 0x01)
        ..writeRegister(0x5011, 0x7f);

      expect(audio.pcmLevel, 0x40);
    });

    test('debugOutputs reports the PCM level in lane 2', () {
      audio.writeRegister(0x5011, 0x33);

      expect(audio.debugOutputs, [0, 0, 0x33]);
    });
  });
}
