import 'package:nes/extension/hex_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cpu/cpu.dart';

typedef AddressReader = (int, bool) Function(CPU, int);
typedef AddressModeDebugger = String Function(CPU, int, List<int>, int);

class AddressMode {
  AddressMode(this.read, this.operandCount, this.debug);

  final AddressReader read;
  final int operandCount;
  final AddressModeDebugger debug;
}

bool wasPageCrossed(int from, int to) => from & 0xff00 != to & 0xff00;

final implicit = AddressMode(
  (cpu, pc) => (addressNone, false),
  0,
  (cpu, pc, operands, address) => '',
);
final accumulator = AddressMode(
  (cpu, pc) => (addressA, false),
  0,
  (cpu, pc, operands, address) => 'A',
);
final immediate = AddressMode(
  (cpu, pc) => (pc, false),
  1,
  (cpu, pc, operands, address) => '#\$${operands[0].toHex()}',
);
final zeroPage = AddressMode(
  (cpu, pc) => (cpu.read(pc) & 0xff, false),
  1,
  (cpu, pc, operands, address) => '\$${operands[0].toHex()}',
);
final zeroPageX = AddressMode(
  (cpu, pc) => ((cpu.read(pc) + cpu.X) & 0xff, false),
  1,
  (cpu, pc, operands, address) =>
      '\$${operands[0].toHex()},X @ ${address.toHex()}',
);
final zeroPageY = AddressMode(
  (cpu, pc) => ((cpu.read(pc) + cpu.Y) & 0xff, false),
  1,
  (cpu, pc, operands, address) =>
      '\$${operands[0].toHex()},Y @ ${address.toHex()}',
);
final relative = AddressMode(
  (cpu, pc) {
    final offset = cpu.read(pc);
    final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;

    return (pc + 1 + offsetSigned, false);
  },
  1,
  (cpu, pc, operands, address) => '\$${address.toHex(4)}',
);
final absolute = AddressMode(
  (cpu, pc) => (cpu.read16(pc), false),
  2,
  (cpu, pc, operands, address) => '\$${address.toHex(4)}',
);
final absoluteX = AddressMode(
  (cpu, pc) {
    final address = cpu.read16(pc);
    final targetAddress = address + cpu.X;

    return (targetAddress, wasPageCrossed(address, targetAddress));
  },
  2,
  (cpu, pc, operands, address) =>
      '\$${cpu.read16(pc).toHex(4)},X @ ${address.toHex(4)}',
);
final absoluteY = AddressMode(
  (cpu, pc) {
    final address = cpu.read16(pc);
    final targetAddress = (address + cpu.Y) & 0xffff;

    return (targetAddress, wasPageCrossed(address, targetAddress));
  },
  2,
  (cpu, pc, operands, address) =>
      '\$${cpu.read16(pc).toHex(4)},Y' ' @ ${address.toHex(4)}',
);
final indirect = AddressMode(
  (cpu, pc) {
    final address = cpu.read16(pc);
    final targetAddress = cpu.read16(address, wrap: true);

    return (targetAddress, false);
  },
  2,
  (cpu, pc, operands, address) =>
      '(\$${operands[1].toHex()}${operands[0].toHex()}) = ${address.toHex(4)}',
);
final indexedIndirect = AddressMode(
  (cpu, pc) {
    final address = (cpu.read(pc) + cpu.X) & 0xff;
    final targetAddress = cpu.read16(address, wrap: true);

    return (targetAddress, false);
  },
  1,
  (cpu, pc, operands, address) => '(\$${operands[0].toHex()},X)'
      ' @ ${((cpu.read(pc) + cpu.X) & 0xff).toHex()}'
      ' = ${address.toHex(4)}',
);
final indirectIndexed = AddressMode(
  (cpu, pc) {
    final zeroPageAddress = cpu.read(pc);
    final address = cpu.read16(zeroPageAddress, wrap: true);
    final targetAddress = (address + cpu.Y) & 0xffff;

    return (targetAddress, wasPageCrossed(address, targetAddress));
  },
  1,
  (cpu, pc, operands, address) => '(\$${operands[0].toHex()}),Y'
      ' = ${cpu.read16(cpu.read(pc), wrap: true).toHex(4)}'
      ' @ ${address.toHex(4)}',
);
