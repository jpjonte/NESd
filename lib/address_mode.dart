import 'package:nes/cpu.dart';

typedef AddressReader = (int, int) Function(CPU);

class AddressMode {
  AddressMode(this.name, this.read);

  final String name;
  final AddressReader read;
}

final implicit = AddressMode('Implicit', (cpu) => (0, 0));
final accumulator = AddressMode('Accumulator', (cpu) => (-1, cpu.A));
final immediate = AddressMode('Immediate', (cpu) => (0, cpu.read(cpu.PC++)));
final zeroPage = AddressMode('Zero Page', (cpu) {
  final address = cpu.read(cpu.PC++);

  return (address, cpu.read(address));
});
final zeroPageX = AddressMode('Zero Page,X', (cpu) {
  final address = (cpu.read(cpu.PC++) + cpu.X) & 0xff;

  return (address, cpu.read(address));
});
final zeroPageY = AddressMode('Zero Page,Y', (cpu) {
  final address = (cpu.read(cpu.PC++) + cpu.Y) & 0xff;

  return (address, cpu.read(address));
});
final relative = AddressMode('Relative', (cpu) {
  final offset = cpu.read(cpu.PC++);
  final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;

  return (cpu.PC - 1 + offsetSigned, offsetSigned);
});
final absolute = AddressMode('Absolute', (cpu) {
  final address = cpu.read16(cpu.PC);

  cpu.PC += 2;

  return (address, cpu.read(address));
});
final absoluteX = AddressMode('Absolute,X', (cpu) {
  final address = cpu.read16(cpu.PC) + cpu.X;

  cpu.PC += 2;

  return (address, cpu.read(address));
});
final absoluteY = AddressMode('Absolute,Y', (cpu) {
  final address = cpu.read16(cpu.PC) + cpu.Y;

  cpu.PC += 2;

  return (address, cpu.read(address));
});
final indirect = AddressMode('Indirect', (cpu) {
  final address = cpu.read16(cpu.PC);

  cpu.PC += 2;

  return (address, cpu.read16(address));
});
final indexedIndirect = AddressMode('Indexed Indirect', (cpu) {
  final address = cpu.read(cpu.PC++) + cpu.X;

  return (address, cpu.read16(address & 0xff));
});
final indirectIndexed = AddressMode('Indirect Indexed', (cpu) {
  final address = cpu.read(cpu.PC++);

  return (address, cpu.read16(address) + cpu.Y);
});
