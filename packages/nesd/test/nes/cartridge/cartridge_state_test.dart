import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';

void main() {
  test('deserializes a version 1 envelope with an 8-bit mapper id', () {
    final writer = Payload.write()
      ..set(uint8, 1) // CartridgeState envelope version
      ..set(uint8List(lengthType: uint32), Uint8List(0)) // chrRam
      ..set(uint8List(lengthType: uint32), Uint8List(0)) // prgRam
      ..set(uint8List(lengthType: uint16), Uint8List(0)) // prgSaveRam
      ..set(uint8, 0) // mapperId, 8-bit
      ..set(uint8, 0) // MapperState envelope version
      ..set(uint8, 0); // mapper id, 8-bit (NROM)

    final decoded = CartridgeState.deserialize(Payload.read(binarize(writer)));

    expect(decoded.mapperId, 0);
    expect(decoded.mapperState, isA<NROMState>());
  });

  test('round-trips a mapper id above 255', () {
    final original = CartridgeState(
      chrRam: Uint8List(0),
      prgRam: Uint8List(0),
      prgSaveRam: Uint8List(0),
      mapperId: 256,
      mapperState: const NROMState(),
    );

    final writer = Payload.write();

    original.serialize(writer);

    final decoded = CartridgeState.deserialize(Payload.read(binarize(writer)));

    expect(decoded.mapperId, 256);
  });
}
