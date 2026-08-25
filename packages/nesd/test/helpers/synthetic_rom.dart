import 'dart:typed_data';

/// Minimal valid NROM image: 16-byte iNES header, one 16K PRG bank
/// looping `JMP $8000`, one 8K CHR bank of zeroes. Keeps web smoke
/// tests free of ROM files so they can run on every platform.
Uint8List syntheticNrom() {
  final header = Uint8List(16)
    ..setAll(0, const [0x4E, 0x45, 0x53, 0x1A, 1, 1, 0, 0]);

  final prg = Uint8List(16384);
  prg[0] = 0x4C; // JMP $8000
  prg[1] = 0x00;
  prg[2] = 0x80;
  prg[0x3FFC] = 0x00; // reset vector -> $8000 (16K bank mirrored)
  prg[0x3FFD] = 0x80;

  final chr = Uint8List(8192);

  return Uint8List.fromList([...header, ...prg, ...chr]);
}
