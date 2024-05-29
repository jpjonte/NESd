import 'package:nes/cpu.dart';
import 'package:nes/hex_extension.dart';

typedef AddressReader = (int, bool) Function(CPU);

class AddressMode {
  AddressMode(this.read, this.operandCount, this.debug);

  final AddressReader read;
  final int operandCount;
  final String Function(CPU, List<int>, int) debug;
}

bool pageCrossed(int from, int to) => from & 0xff00 != to & 0xff00;

const addressNone = -1;
const addressA = -2;

final implicit = AddressMode(
  (cpu) => (addressNone, false),
  0,
  (cpu, operands, address) => '',
);
final accumulator = AddressMode(
  (cpu) => (addressA, false),
  0,
  (cpu, operands, address) => 'A',
);
final immediate = AddressMode(
  (cpu) => (cpu.PC++, false),
  1,
  (cpu, operands, address) => '#\$${operands[0].toHex()}',
);
final zeroPage = AddressMode(
  (cpu) => (cpu.read(cpu.PC++) & 0xff, false),
  1,
  (cpu, operands, address) => '\$${operands[0].toHex()}',
);
final zeroPageX = AddressMode(
  (cpu) => ((cpu.read(cpu.PC++) + cpu.X) & 0xff, false),
  1,
  (cpu, operands, address) => '\$${operands[0].toHex()},X @ ${address.toHex()}',
);
final zeroPageY = AddressMode(
  (cpu) => ((cpu.read(cpu.PC++) + cpu.Y) & 0xff, false),
  1,
  (cpu, operands, address) => '\$${operands[0].toHex()},Y @ ${address.toHex()}',
);
final relative = AddressMode(
  (cpu) {
    final offset = cpu.read(cpu.PC++);
    final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;

    return (cpu.PC + offsetSigned, false);
  },
  1,
  (cpu, operands, address) => '\$${address.toHex(4)}',
);
final absolute = AddressMode(
  (cpu) {
    final address = cpu.read16(cpu.PC);

    cpu.PC += 2;

    return (address, false);
  },
  2,
  (cpu, operands, address) => '\$${address.toHex(4)}',
);
final absoluteX = AddressMode(
  (cpu) {
    final address = cpu.read16(cpu.PC);
    final targetAddress = address + cpu.X;

    cpu.PC += 2;

    return (targetAddress, pageCrossed(address, targetAddress));
  },
  2,
  (cpu, operands, address) =>
      '\$${cpu.read16(cpu.PC - 2).toHex(4)},X @ ${address.toHex(4)}',
);
final absoluteY = AddressMode(
  (cpu) {
    final address = cpu.read16(cpu.PC);
    final targetAddress = (address + cpu.Y) & 0xffff;

    cpu.PC += 2;

    return (targetAddress, pageCrossed(address, targetAddress));
  },
  2,
  (cpu, operands, address) =>
      '\$${cpu.read16(cpu.PC - 2).toHex(4)},Y' ' @ ${address.toHex(4)}',
);
final indirect = AddressMode(
  (cpu) {
    final address = cpu.read16(cpu.PC);
    final targetAddress = cpu.read16(address, wrap: true);

    cpu.PC += 2;

    return (targetAddress, false);
  },
  2,
  (cpu, operands, address) =>
      '(\$${operands[1].toHex()}${operands[0].toHex()}) = ${address.toHex(4)}',
);
final indexedIndirect = AddressMode(
  (cpu) {
    final address = (cpu.read(cpu.PC++) + cpu.X) & 0xff;
    final targetAddress = cpu.read16(address, wrap: true);

    return (targetAddress, false);
  },
  1,
  (cpu, operands, address) => '(\$${operands[0].toHex()},X)'
      ' @ ${((cpu.read(cpu.PC - 1) + cpu.X) & 0xff).toHex()}'
      ' = ${address.toHex(4)}',
);
final indirectIndexed = AddressMode(
  (cpu) {
    final zeroPageAddress = cpu.read(cpu.PC++);
    final address = cpu.read16(zeroPageAddress, wrap: true);
    final targetAddress = (address + cpu.Y) & 0xffff;

    return (targetAddress, pageCrossed(address, targetAddress));
  },
  1,
  (cpu, operands, address) => '(\$${operands[0].toHex()}),Y'
      ' = ${cpu.read16(cpu.read(cpu.PC - 1), wrap: true).toHex(4)}'
      ' @ ${address.toHex(4)}',
);
