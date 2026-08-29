import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/channel/pulse_channel.dart';

List<int> waveform(PulseChannel pulse) {
  final levels = <int>[];

  for (var i = 0; i < 8; i++) {
    pulse
      ..dutyIndex = i
      ..updateOutput();

    levels.add(pulse.output);
  }

  return levels;
}

PulseChannel audiblePulse({required int duty, int phase = 0}) => PulseChannel()
  ..enabled = true
  ..constantVolume = true
  ..volume = 1
  ..duty = duty
  ..dutyIndex = phase
  ..lengthCounter.value = 10
  ..updateOutput();

const eighth = [0, 0, 0, 0, 0, 0, 0, 1];
const quarter = [0, 0, 0, 0, 0, 0, 1, 1];
const half = [0, 0, 0, 0, 1, 1, 1, 1];
const quarterNegated = [1, 1, 1, 1, 1, 1, 0, 0];

void main() {
  group('duty cycle swap', () {
    test('duty 1 emits the 50% waveform', () {
      final pulse = audiblePulse(duty: 1)..swapDutyCycles = true;

      expect(waveform(pulse), half);
    });

    test('duty 2 emits the 25% waveform', () {
      final pulse = audiblePulse(duty: 2)..swapDutyCycles = true;

      expect(waveform(pulse), quarter);
    });

    test('duty 0 is unchanged', () {
      final pulse = audiblePulse(duty: 0)..swapDutyCycles = true;

      expect(waveform(pulse), eighth);
    });

    test('duty 3 is unchanged', () {
      final pulse = audiblePulse(duty: 3)..swapDutyCycles = true;

      expect(waveform(pulse), quarterNegated);
    });

    test('is off by default', () {
      final pulse = audiblePulse(duty: 1);

      expect(pulse.swapDutyCycles, isFalse);
      expect(waveform(pulse), quarter);
    });

    test('applies to a duty written after it is enabled', () {
      final pulse = audiblePulse(duty: 0)
        ..swapDutyCycles = true
        // duty 1, constant volume 1
        ..writeControl(0x40 | 0x10 | 0x01);

      expect(waveform(pulse), half);
    });

    test('enabling it mid-note changes the output immediately', () {
      // Phase 4 is low at 25% and high at 50%.
      final pulse = audiblePulse(duty: 1, phase: 4);

      expect(pulse.output, 0);

      pulse.swapDutyCycles = true;

      expect(pulse.output, 1);
    });

    test('enabling it mid-note preserves the phase', () {
      final pulse = audiblePulse(duty: 2, phase: 3);

      expect(pulse.dutyIndex, 3);

      pulse.swapDutyCycles = true;

      expect(pulse.dutyIndex, 3);
    });

    test('disabling it restores the register waveform', () {
      final pulse = audiblePulse(duty: 1)..swapDutyCycles = true;

      expect(waveform(pulse), half);

      pulse.swapDutyCycles = false;

      expect(waveform(pulse), quarter);
    });

    test('survives a save state round trip', () {
      final pulse = audiblePulse(duty: 1)..swapDutyCycles = true;

      final restored = audiblePulse(duty: 0)
        ..swapDutyCycles = true
        ..state = pulse.state;

      expect(waveform(restored), half);
    });

    test('is not carried by the save state', () {
      final pulse = audiblePulse(duty: 1)..swapDutyCycles = true;

      final restored = audiblePulse(duty: 0)..state = pulse.state;

      expect(restored.swapDutyCycles, isFalse);
      expect(waveform(restored), quarter);
    });
  });
}
