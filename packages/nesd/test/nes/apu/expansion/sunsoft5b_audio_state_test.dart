import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio_state.dart';
import 'package:nesd/nes/apu/tables.dart';

void main() {
  Sunsoft5BAudioState roundTrip(Sunsoft5BAudioState state) {
    final writer = Payload.write();

    state.serialize(writer);

    return Sunsoft5BAudioState.deserialize(Payload.read(binarize(writer)));
  }

  Sunsoft5BAudio playingChip() {
    final audio = Sunsoft5BAudio()
      ..writeAddress(0x00)
      ..writeData(0x05)
      ..writeAddress(0x06)
      ..writeData(0x03)
      ..writeAddress(0x07)
      ..writeData(0x36)
      ..writeAddress(0x08)
      ..writeData(0x10)
      ..writeAddress(0x0b)
      ..writeData(0x02)
      ..writeAddress(0x0d)
      ..writeData(0x0a);

    for (var i = 0; i < sunsoft5bPrescaler * 40 + 3; i++) {
      audio.step();
    }

    return audio;
  }

  test('a restored chip keeps playing where it left off', () {
    final audio = playingChip();

    final restored = Sunsoft5BAudio()..state = roundTrip(audio.state);

    expect(restored.output, audio.output);
    expect(restored.envelopeLevel, audio.envelopeLevel);
    expect(restored.noiseShift, audio.noiseShift);

    for (var i = 0; i < sunsoft5bPrescaler * 8; i++) {
      audio.step();
      restored.step();
    }

    expect(restored.output, audio.output);
    expect(restored.envelopeLevel, audio.envelopeLevel);
    expect(restored.noiseShift, audio.noiseShift);
    expect(restored.debugOutputs, audio.debugOutputs);
  });

  test('the registers and the address port round-trip', () {
    final audio = playingChip()..writeAddress(0x1c);

    final restored = Sunsoft5BAudio()..state = roundTrip(audio.state);

    expect(restored.registers, audio.registers);
    expect(restored.address, 0x0c);
    expect(restored.writesDisabled, true);
  });
}
