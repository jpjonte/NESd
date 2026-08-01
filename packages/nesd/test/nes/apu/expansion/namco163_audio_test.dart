import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio.dart';

void main() {
  late Namco163Audio audio;

  setUp(() => audio = Namco163Audio(0));

  group('address port', () {
    test('bits 0-6 set the address', () {
      audio.writeAddress(0x3f);

      expect(audio.address, 0x3f);
      expect(audio.autoIncrement, false);
    });

    test('bit 7 enables auto-increment and is masked out of the address', () {
      audio.writeAddress(0xc5);

      expect(audio.address, 0x45);
      expect(audio.autoIncrement, true);
    });
  });

  group('data port', () {
    test('writes and reads sound RAM at the latched address', () {
      audio
        ..writeAddress(0x10)
        ..writeData(0xab);

      expect(audio.ram[0x10], 0xab);

      audio.writeAddress(0x10);

      expect(audio.readData(), 0xab);
    });

    test('auto-increment advances on writes', () {
      audio
        ..writeAddress(0x80 | 0x10)
        ..writeData(0x11)
        ..writeData(0x22);

      expect(audio.ram[0x10], 0x11);
      expect(audio.ram[0x11], 0x22);
      expect(audio.address, 0x12);
    });

    test('auto-increment advances on reads', () {
      audio
        ..writeAddress(0x80 | 0x10)
        ..writeData(0x11)
        ..writeData(0x22)
        ..writeAddress(0x80 | 0x10);

      expect(audio.readData(), 0x11);
      expect(audio.readData(), 0x22);
    });

    test('auto-increment stops at 0x7f instead of wrapping', () {
      audio
        ..writeAddress(0x80 | 0x7f)
        ..writeData(0x33)
        ..writeData(0x44);

      expect(audio.address, 0x7f);
      expect(audio.ram[0x7f], 0x44);
      expect(audio.ram[0x00], 0x00);
    });

    test('disableSideEffects leaves the address latch alone', () {
      audio
        ..writeAddress(0x80 | 0x10)
        ..writeData(0x11)
        ..writeAddress(0x80 | 0x10);

      expect(audio.readData(disableSideEffects: true), 0x11);
      expect(audio.address, 0x10);
    });

    test('without auto-increment the address never moves', () {
      audio
        ..writeAddress(0x10)
        ..writeData(0x11)
        ..writeData(0x22);

      expect(audio.ram[0x10], 0x22);
      expect(audio.ram[0x11], 0x00);
      expect(audio.address, 0x10);
    });
  });

  group('reset', () {
    test('clears RAM and the latch', () {
      audio
        ..writeAddress(0x80 | 0x10)
        ..writeData(0xab)
        ..reset();

      expect(audio.ram[0x10], 0);
      expect(audio.address, 0);
      expect(audio.autoIncrement, false);
    });
  });
}
