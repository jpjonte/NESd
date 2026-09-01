// Builds the UNROM 512 flash test ROM in roms/test/unrom512_flash/.
//
// The ROM boots, reads a counter byte out of flash, increments it, erases
// the sector holding it and programs the new value back, then spins. Its
// counter goes up by one on every power cycle.

import 'dart:io';
import 'dart:typed_data';

const prgBanks = 2;
const prgSize = prgBanks * 0x4000;

const routineBase = 0x0200;

const valueSlot = 0x00;

const counterAddress = 0x8000;

List<int> ldaImm(int v) => [0xa9, v];
List<int> ldaAbs(int a) => [0xad, a & 0xff, a >> 8];
List<int> ldaZp(int a) => [0xa5, a];
List<int> staAbs(int a) => [0x8d, a & 0xff, a >> 8];
List<int> staZp(int a) => [0x85, a];
List<int> cmpImm(int v) => [0xc9, v];
List<int> cmpZp(int a) => [0xc5, a];
List<int> jsr(int a) => [0x20, a & 0xff, a >> 8];
List<int> jmp(int a) => [0x4c, a & 0xff, a >> 8];

List<int> branchBack(int opcode, int distance) => [opcode, 256 - distance];

List<int> selectBank(int bank) => [...ldaImm(bank), ...staAbs(0xc000)];

List<int> command(int bank, int address, int value) => [
  ...selectBank(bank),
  ...ldaImm(value),
  ...staAbs(address),
];

List<int> get unlock => [
  ...command(1, 0x9555, 0xaa),
  ...command(0, 0xaaaa, 0x55),
];

List<int> pollUntil(List<int> compare) => [
  ...ldaAbs(counterAddress),
  ...compare,
  ...branchBack(0xd0, 7), // BNE
];

List<int> get eraseSector => [
  ...unlock,
  ...command(1, 0x9555, 0x80),
  ...unlock,
  ...selectBank(0),
  ...ldaImm(0x30),
  ...staAbs(counterAddress),
  ...pollUntil(cmpImm(0xff)),
  0x60, // RTS
];

List<int> get writeByte => [
  ...unlock,
  ...command(1, 0x9555, 0xa0),
  ...selectBank(0),
  ...ldaZp(valueSlot),
  ...staAbs(counterAddress),
  ...pollUntil(cmpZp(valueSlot)),
  0x60, // RTS
];

void main() {
  final erase = eraseSector;
  final write = writeByte;
  final routine = [...erase, ...write];

  const eraseEntry = routineBase;
  final writeEntry = routineBase + erase.length;

  final prg = Uint8List(prgSize)..fillRange(0, prgSize, 0xff);

  prg[0] = 0x00;

  const bank1 = 0x4000;

  var offset = bank1;

  int emit(List<int> bytes) {
    final at = offset;

    prg.setRange(offset, offset + bytes.length, bytes);
    offset += bytes.length;

    return at;
  }

  final routineData = emit(routine);
  final routineDataAddress = 0xc000 + (routineData - bank1);

  final reset = offset;

  emit([
    0x78, // SEI
    0xd8, // CLD
    0xa2, 0xff, // LDX #$ff
    0x9a, // TXS
    ...ldaImm(0x00),
    ...staAbs(0x2000), // no NMI
    ...staAbs(0x2001), // no rendering
    // copy the flash routine into CPU RAM, backwards
    0xa2, routine.length - 1, // LDX #len-1
    0xbd, routineDataAddress & 0xff, routineDataAddress >> 8, // LDA data,X
    0x9d, routineBase & 0xff, routineBase >> 8, // STA $0200,X
    0xca, // DEX
    ...branchBack(0x10, 9), // BPL, over the 9 bytes above
    // read the counter, treating an erased byte as zero
    ...selectBank(0),
    ...ldaAbs(counterAddress),
    ...cmpImm(0xff),
    0xd0, 0x02, // BNE over the next two bytes
    ...ldaImm(0x00),
    0x18, // CLC
    0x69, 0x01, // ADC #$01
    ...staZp(valueSlot),
    ...jsr(eraseEntry),
    ...jsr(writeEntry),
  ]);

  final forever = 0xc000 + (offset - bank1);

  emit(jmp(forever));

  final rti = 0xc000 + (offset - bank1);

  emit([0x40]); // RTI

  const vectors = bank1 + 0x4000 - 6;

  prg.setRange(vectors, vectors + 6, [
    rti & 0xff, rti >> 8, // NMI
    (0xc000 + (reset - bank1)) & 0xff, (0xc000 + (reset - bank1)) >> 8, // RESET
    rti & 0xff, rti >> 8, // IRQ
  ]);

  final header = Uint8List(16)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a,
      prgBanks, // PRG-ROM in 16 KiB units
      0, // no CHR-ROM, this is a CHR-RAM board
      0xe2, // mapper 30 low nibble, battery set, vertical arrangement
      0x18, // mapper 30 high nibble, NES 2.0 marker
      0x00, // submapper 0
      0x00,
      0x00, // no PRG-RAM, no PRG-NVRAM
      0x09, // 64 << 9 = 32 KiB CHR-RAM
      0x00,
      0x00,
      0x00,
      0x00,
    ]);

  final root = File.fromUri(Platform.script).parent.parent.parent.parent;
  final out = Directory('${root.path}/roms/test/unrom512_flash')
    ..createSync(recursive: true);
  final file = File('${out.path}/unrom512_flash.nes')
    ..writeAsBytesSync(Uint8List.fromList([...header, ...prg]));

  stdout
    ..writeln(
      'routine ${routine.length} bytes '
      '(erase @ ${eraseEntry.toRadixString(16)}, '
      'write @ ${writeEntry.toRadixString(16)})',
    )
    ..writeln('reset @ ${(0xc000 + (reset - bank1)).toRadixString(16)}')
    ..writeln('wrote ${file.path} (${file.lengthSync()} bytes)');
}
