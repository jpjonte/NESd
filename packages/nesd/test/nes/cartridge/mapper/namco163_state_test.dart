import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio_state.dart';
import 'package:nesd/nes/apu/tables.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/namco163_state.dart';

void main() {
  Namco163State roundTrip(Namco163State state) {
    final writer = Payload.write();

    state.serialize(writer);

    return MapperState.deserialize(Payload.read(binarize(writer)))
        as Namco163State;
  }

  Namco163State buildState({required Namco163AudioState audioState}) =>
      Namco163State(
        prgBank0: 1,
        prgBank1: 2,
        prgBank2: 3,
        prgRamWriteProtect: const [true, false, true, false],
        chrBanks: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        disableNametables0: true,
        disableNametables1: false,
        irqCounter: 0x1234,
        irqEnabled: true,
        audioState: audioState,
      );

  test('version 1 round-trips the mapper fields', () {
    final result = buildState(audioState: Namco163AudioState.initial());

    final restored = roundTrip(result);

    expect(restored.prgBank0, 1);
    expect(restored.prgBank1, 2);
    expect(restored.prgBank2, 3);
    expect(restored.prgRamWriteProtect, [true, false, true, false]);
    expect(restored.chrBanks, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    expect(restored.disableNametables0, true);
    expect(restored.disableNametables1, false);
    expect(restored.irqCounter, 0x1234);
    expect(restored.irqEnabled, true);
  });

  test('version 1 round-trips the audio state', () {
    final ram = Uint8List(0x80)
      ..[0x00] = 0xab
      ..[0x7f] = 0x30;

    final audioState = Namco163AudioState(
      ram: ram,
      channelOutput: Int8List.fromList(const [-120, -8, 0, 7, 105, 0, 0, -1]),
      address: 0x42,
      autoIncrement: true,
      soundDisabled: false,
      slotTimer: 7,
      slot: 3,
    );

    final restored = roundTrip(buildState(audioState: audioState)).audioState;

    expect(restored.ram[0x00], 0xab);
    expect(restored.ram[0x7f], 0x30);
    expect(restored.ram, hasLength(0x80));
    expect(restored.channelOutput, [-120, -8, 0, 7, 105, 0, 0, -1]);
    expect(restored.address, 0x42);
    expect(restored.autoIncrement, true);
    expect(restored.soundDisabled, false);
    expect(restored.slotTimer, 7);
    expect(restored.slot, 3);
  });

  test('version 0 loads with silent audio defaults', () {
    // `MapperState.serialize` writes its own version byte and the mapper
    // id; `Namco163State` then writes its version byte and its fields.
    // This is a version 0 payload, so no audio state follows.
    final writer = Payload.write()
      ..set(uint8, 0) // MapperState version
      ..set(uint8, 19) // mapper id
      ..set(uint8, 0) // Namco163State version
      ..set(uint8, 1)
      ..set(uint8, 2)
      ..set(uint8, 3)
      ..set(list(boolean), const [true, false, true, false])
      ..set(list(uint8), const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
      ..set(boolean, true)
      ..set(boolean, false)
      ..set(uint16, 0x1234)
      ..set(boolean, true);

    final restored =
        MapperState.deserialize(Payload.read(binarize(writer)))
            as Namco163State;

    expect(restored.prgBank0, 1);
    expect(restored.irqCounter, 0x1234);
    expect(restored.audioState.ram.every((b) => b == 0), true);
    expect(restored.audioState.channelOutput.every((v) => v == 0), true);
    expect(restored.audioState.address, 0);
    expect(restored.audioState.autoIncrement, false);
    expect(restored.audioState.soundDisabled, false);
    expect(restored.audioState.slotTimer, n163SlotCycles);
    expect(restored.audioState.slot, 0);
  });
}
