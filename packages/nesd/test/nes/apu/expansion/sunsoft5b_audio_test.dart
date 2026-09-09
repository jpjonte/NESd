import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio.dart';
import 'package:nesd/nes/apu/tables.dart';

void main() {
  late Sunsoft5BAudio audio;

  setUp(() => audio = Sunsoft5BAudio());

  void writeRegister(int register, int value) {
    audio
      ..writeAddress(register)
      ..writeData(value);
  }

  void steps(int count) {
    for (var i = 0; i < count; i++) {
      audio.step();
    }
  }

  void playToneA(int period) {
    writeRegister(0x00, period & 0xff);
    writeRegister(0x01, period >> 8);
    writeRegister(0x07, 0x3e);
    writeRegister(0x08, 0x0f);
  }

  group('register port', () {
    test('the address port keeps the low four bits', () {
      audio.writeAddress(0x35);

      expect(audio.address, 0x05);
    });

    test('the data port writes the latched register', () {
      writeRegister(0x0b, 0xab);

      expect(audio.registers[0x0b], 0xab);
    });

    test('consecutive writes go to the same register', () {
      writeRegister(0x02, 0x11);

      audio.writeData(0x22);

      expect(audio.registers[0x02], 0x22);
    });
  });

  group('tone generator', () {
    test('a channel toggles every 16 CPU cycles per period unit', () {
      playToneA(2);

      expect(audio.output, 0);

      steps(sunsoft5bPrescaler * 2);

      expect(audio.output, greaterThan(0));

      steps(sunsoft5bPrescaler * 2);

      expect(audio.output, 0);
    });

    test('the period spans twelve bits', () {
      playToneA(0x123);

      steps(sunsoft5bPrescaler * 0x123 - 1);

      expect(audio.output, 0);

      audio.step();

      expect(audio.output, greaterThan(0));
    });

    test('period 0 runs as fast as period 1', () {
      playToneA(0);

      steps(sunsoft5bPrescaler);

      expect(audio.output, greaterThan(0));
    });

    test('a disabled tone leaves the channel at its full level', () {
      playToneA(2);

      writeRegister(0x07, 0x3f);

      expect(audio.output, greaterThan(0));

      steps(sunsoft5bPrescaler * 2);

      expect(audio.output, greaterThan(0));
    });
  });

  void playNoiseA(int period) {
    writeRegister(0x06, period);
    writeRegister(0x07, 0x37);
    writeRegister(0x08, 0x0f);
  }

  void playEnvelopeA({required int period, required int shape}) {
    writeRegister(0x07, 0x3f);
    writeRegister(0x08, 0x10);
    writeRegister(0x0b, period & 0xff);
    writeRegister(0x0c, period >> 8);
    writeRegister(0x0d, shape);
  }

  group('volume', () {
    test('volume 15 reaches full scale', () {
      playToneA(1);

      steps(sunsoft5bPrescaler);

      expect(audio.output, closeTo(sunsoft5bScale, 1e-9));
    });

    test('volume 0 is silent', () {
      playToneA(1);

      writeRegister(0x08, 0x00);

      steps(sunsoft5bPrescaler);

      expect(audio.output, 0);
    });

    test('each volume step is 3 dB', () {
      playToneA(1);

      steps(sunsoft5bPrescaler);

      final full = audio.output;

      writeRegister(0x08, 0x0e);

      expect(audio.output / full, closeTo(0.7079, 1e-3));
    });
  });

  group('address port write lock', () {
    test('an address above 15 blocks the data port', () {
      writeRegister(0x02, 0x11);

      audio
        ..writeAddress(0x12)
        ..writeData(0x22);

      expect(audio.registers[0x02], 0x11);
    });

    test('a valid address unlocks the data port again', () {
      audio.writeAddress(0x12);

      writeRegister(0x02, 0x22);

      expect(audio.registers[0x02], 0x22);
    });
  });

  group('noise generator', () {
    test('a new bit arrives every 32 CPU cycles per period unit', () {
      playNoiseA(1);

      expect(audio.output, greaterThan(0));

      steps(2 * sunsoft5bPrescaler - 1);

      expect(audio.output, greaterThan(0));

      audio.step();

      expect(audio.output, 0);
    });

    test('the period scales the shift rate', () {
      playNoiseA(3);

      steps(2 * sunsoft5bPrescaler * 3 - 1);

      expect(audio.output, greaterThan(0));

      audio.step();

      expect(audio.output, 0);
    });

    test('the shift register is 17 bits with taps three apart', () {
      playNoiseA(1);

      final shifts = <int>[];

      for (var i = 0; i < 4; i++) {
        steps(2 * sunsoft5bPrescaler);

        shifts.add(audio.noiseShift);
      }

      expect(shifts, [0x10000, 0x08000, 0x04000, 0x02000]);
    });

    test('a channel with tone and noise enabled ands them together', () {
      playNoiseA(1);

      writeRegister(0x00, 1);
      writeRegister(0x07, 0x36);

      expect(audio.output, 0);

      steps(sunsoft5bPrescaler);

      expect(audio.output, greaterThan(0));
    });
  });

  group('envelope generator', () {
    test('a channel in envelope mode follows the envelope level', () {
      playEnvelopeA(period: 1, shape: 0x08);

      expect(audio.output, closeTo(sunsoft5bScale, 1e-9));
    });

    test('a step takes 16 CPU cycles per period unit', () {
      playEnvelopeA(period: 2, shape: 0x08);

      steps(2 * sunsoft5bPrescaler - 1);

      expect(audio.envelopeLevel, 31);

      audio.step();

      expect(audio.envelopeLevel, 30);
    });

    test('shape 8 repeats a falling ramp', () {
      playEnvelopeA(period: 1, shape: 0x08);

      steps(sunsoft5bPrescaler * 31);

      expect(audio.envelopeLevel, 0);

      steps(sunsoft5bPrescaler);

      expect(audio.envelopeLevel, 31);
    });

    test('shape C repeats a rising ramp', () {
      playEnvelopeA(period: 1, shape: 0x0c);

      expect(audio.envelopeLevel, 0);

      steps(sunsoft5bPrescaler * 31);

      expect(audio.envelopeLevel, 31);

      steps(sunsoft5bPrescaler);

      expect(audio.envelopeLevel, 0);
    });

    test('shape 9 holds at zero', () {
      playEnvelopeA(period: 1, shape: 0x09);

      steps(sunsoft5bPrescaler * 64);

      expect(audio.envelopeLevel, 0);
    });

    test('shape B holds at the maximum', () {
      playEnvelopeA(period: 1, shape: 0x0b);

      steps(sunsoft5bPrescaler * 64);

      expect(audio.envelopeLevel, 31);
    });

    test('shape D holds at the maximum', () {
      playEnvelopeA(period: 1, shape: 0x0d);

      steps(sunsoft5bPrescaler * 64);

      expect(audio.envelopeLevel, 31);
    });

    test('shape F holds at zero', () {
      playEnvelopeA(period: 1, shape: 0x0f);

      steps(sunsoft5bPrescaler * 64);

      expect(audio.envelopeLevel, 0);
    });

    test('shape E alternates between ramps', () {
      playEnvelopeA(period: 1, shape: 0x0e);

      steps(sunsoft5bPrescaler * 32);

      expect(audio.envelopeLevel, 31);

      steps(sunsoft5bPrescaler * 31);

      expect(audio.envelopeLevel, 0);
    });

    test('a shape without the continue bit ends silent', () {
      playEnvelopeA(period: 1, shape: 0x04);

      steps(sunsoft5bPrescaler * 31);

      expect(audio.envelopeLevel, 31);

      steps(sunsoft5bPrescaler * 33);

      expect(audio.envelopeLevel, 0);
    });

    test('writing the shape restarts the ramp', () {
      playEnvelopeA(period: 1, shape: 0x08);

      steps(sunsoft5bPrescaler * 10);

      expect(audio.envelopeLevel, 21);

      writeRegister(0x0d, 0x08);

      expect(audio.envelopeLevel, 31);
    });
  });

  group('debug outputs', () {
    test('each channel reports its own level', () {
      playToneA(1);

      writeRegister(0x09, 0x0a);
      writeRegister(0x07, 0x38);

      steps(sunsoft5bPrescaler);

      expect(audio.debugOutputs, [31, 21, 0]);
    });
  });
}
