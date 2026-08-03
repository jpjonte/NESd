import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio.dart';
import 'package:nesd/nes/apu/tables.dart';

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

  void program(
    Namco163Audio audio,
    int index, {
    required int frequency,
    required int length,
    required int waveAddress,
    required int volume,
  }) {
    final base = 0x40 + index * 8;

    audio.ram[base] = frequency & 0xff;
    audio.ram[base + 2] = (frequency >> 8) & 0xff;
    audio.ram[base + 4] = ((256 - length) & 0xfc) | ((frequency >> 16) & 0x03);
    audio.ram[base + 6] = waveAddress;
    audio.ram[base + 7] = (audio.ram[base + 7] & 0xf0) | (volume & 0x0f);
  }

  void enable(Namco163Audio audio, int count) {
    audio.ram[0x7f] = (audio.ram[0x7f] & 0x8f) | ((count - 1) << 4);
  }

  group('enabled channels', () {
    test(r'$7f bits 4-6 give the count, one channel minimum', () {
      expect(audio.enabledChannels, 1);

      enable(audio, 8);

      expect(audio.enabledChannels, 8);

      enable(audio, 5);

      expect(audio.enabledChannels, 5);
    });
  });

  group('slot timing', () {
    test('no channel is serviced before 15 CPU cycles have passed', () {
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      audio.ram[0] = 0x0f;

      for (var i = 0; i < 14; i++) {
        audio.step();
      }

      expect(audio.channelOutput[7], 0);
    });

    test('the 15th cycle services the first channel', () {
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      audio.ram[0] = 0x0f;

      for (var i = 0; i < 15; i++) {
        audio.step();
      }

      // phase advances to 1, wave nibble 1 is the high nibble of ram[0]
      expect(audio.channelOutput[7], isNot(0));
    });

    test('four enabled channels rotate 8, 7, 6, 5', () {
      enable(audio, 4);

      final visited = <int>[];

      for (var i = 0; i < 4; i++) {
        for (var c = 0; c < n163SlotCycles; c++) {
          audio.step();
        }

        visited.add(7 - audio.slot);
      }

      expect(visited, [6, 5, 4, 7]);
    });

    test('shrinking the enabled count clamps the rotation', () {
      enable(audio, 8);

      for (var i = 0; i < n163SlotCycles * 6; i++) {
        audio.step();
      }

      expect(audio.slot, 6);

      enable(audio, 2);

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.slot, 0);
    });
  });

  group('channel update', () {
    test('phase accumulates by frequency and wraps at length << 16', () {
      program(
        audio,
        7,
        frequency: 0x8000,
        length: 4,
        waveAddress: 0,
        volume: 0,
      );

      const base = 0x78;

      for (var i = 0; i < n163SlotCycles * 8; i++) {
        audio.step();
      }

      final phase =
          (audio.ram[base + 5] << 16) |
          (audio.ram[base + 3] << 8) |
          audio.ram[base + 1];

      // 8 updates * 0x8000 == 0x40000, which is exactly 4 << 16
      expect(phase, 0);
    });

    test('samples are 4-bit, two per byte, low nibble first', () {
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 1,
      );

      // nibble 0 = 0x3, nibble 1 = 0xc
      audio.ram[0] = 0xc3;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      // phase is now 1, so nibble 1 == 0xc
      expect(audio.channelOutput[7], (0xc - 8) * 1);
    });

    test('output is (sample - 8) * volume', () {
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );

      audio.ram[0] = 0x00;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.channelOutput[7], (0 - 8) * 15);
    });

    test('the wave address offsets the sample index', () {
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 4,
        volume: 1,
      );

      // nibble 5 lives in the high half of ram[2]
      audio.ram[2] = 0xf0;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.channelOutput[7], (0xf - 8) * 1);
    });

    test('accessors expose volume, wave length and frequency', () {
      program(
        audio,
        7,
        frequency: 0x12345,
        length: 32,
        waveAddress: 0,
        volume: 9,
      );

      expect(audio.volumeOf(7), 9);
      expect(audio.waveLengthOf(7), 32);
      expect(audio.frequencyOf(7), 0x12345);
    });
  });

  group('output', () {
    test('carries only the channel currently being serviced', () {
      enable(audio, 2);

      program(
        audio,
        6,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 0,
      );

      audio.ram[0] = 0x00;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.output, isNot(0));

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.output, 0);
    });

    test('scales by the submapper level', () {
      final loud = Namco163Audio(4);

      for (final chip in [audio, loud]) {
        enable(chip, 1);
        program(
          chip,
          7,
          frequency: 0x10000,
          length: 4,
          waveAddress: 0,
          volume: 15,
        );
        chip.ram[0] = 0x00;

        for (var i = 0; i < n163SlotCycles; i++) {
          chip.step();
        }
      }

      expect(audio.output, closeTo(-120 * n163ScaleFor(0), 1e-9));
      expect(loud.output, closeTo(-120 * n163ScaleFor(4), 1e-9));
      expect(loud.output.abs(), greaterThan(audio.output.abs()));
    });

    test('submapper 2 declares no expansion sound and stays silent', () {
      final muted = Namco163Audio(2);

      enable(muted, 1);
      program(
        muted,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      muted.ram[0] = 0x00;

      for (var i = 0; i < n163SlotCycles; i++) {
        muted.step();
      }

      expect(muted.output, 0);
    });

    test('sound disable silences the output but keeps the chip running', () {
      enable(audio, 1);
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      audio.ram[0] = 0x00;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      audio.soundDisabled = true;

      expect(audio.output, 0);
      expect(audio.channelOutput[7], isNot(0));
    });

    test('untagged ROMs get the submapper 3 level', () {
      expect(n163ScaleFor(0), n163ScaleFor(3));
      expect(n163ScaleFor(1), n163ScaleFor(3));
    });
  });

  group('debug outputs', () {
    test('are eight lanes biased into the unsigned byte range', () {
      expect(audio.debugOutputs, hasLength(8));
      expect(audio.debugOutputs.every((v) => v == n163DebugBias), true);

      enable(audio, 1);
      program(
        audio,
        7,
        frequency: 0x10000,
        length: 4,
        waveAddress: 0,
        volume: 15,
      );
      audio.ram[0] = 0x00;

      for (var i = 0; i < n163SlotCycles; i++) {
        audio.step();
      }

      expect(audio.debugOutputs[7], (0 - 8) * 15 + n163DebugBias);
      expect(audio.debugOutputs.every((v) => v >= 0 && v <= 255), true);
    });
  });
}
