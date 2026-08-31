import 'package:nesd/nes/cartridge/mapper/unrom512.dart';

void unlockFlash(UNROM512 mapper) {
  mapper
    ..cpuWrite(0xc000, 0x01)
    ..cpuWrite(0x9555, 0xaa)
    ..cpuWrite(0xc000, 0x00)
    ..cpuWrite(0xaaaa, 0x55);
}

void programFlashByte(
  UNROM512 mapper, {
  required int bank,
  required int address,
  required int value,
}) {
  unlockFlash(mapper);

  mapper
    ..cpuWrite(0xc000, 0x01)
    ..cpuWrite(0x9555, 0xa0)
    ..cpuWrite(0xc000, bank)
    ..cpuWrite(address, value);
}

void eraseFlashSector(
  UNROM512 mapper, {
  required int bank,
  required int address,
}) {
  unlockFlash(mapper);

  mapper
    ..cpuWrite(0xc000, 0x01)
    ..cpuWrite(0x9555, 0x80);

  unlockFlash(mapper);

  mapper
    ..cpuWrite(0xc000, bank)
    ..cpuWrite(address, 0x30);
}

void enterFlashSoftwareId(UNROM512 mapper) {
  unlockFlash(mapper);

  mapper
    ..cpuWrite(0xc000, 0x01)
    ..cpuWrite(0x9555, 0x90);
}

void exitFlashSoftwareId(UNROM512 mapper) {
  mapper.cpuWrite(0x8000, 0xf0);
}
