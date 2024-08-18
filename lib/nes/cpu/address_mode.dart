import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/cpu.dart';

sealed class AddressMode {
  (int, bool) read(CPU cpu, int pc);

  int get operandCount;
}

bool wasPageCrossed(int from, int to) => from & 0xff00 != to & 0xff00;

class Implicit extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => (addressNone, false);

  @override
  int get operandCount => 0;
}

class Accumulator extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => (addressA, false);

  @override
  int get operandCount => 0;
}

class Immediate extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => (pc, false);

  @override
  int get operandCount => 1;
}

class ZeroPage extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => (cpu.read(pc) & 0xff, false);

  @override
  int get operandCount => 1;
}

class ZeroPageX extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => ((cpu.read(pc) + cpu.X) & 0xff, false);

  @override
  int get operandCount => 1;
}

class ZeroPageY extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => ((cpu.read(pc) + cpu.Y) & 0xff, false);

  @override
  int get operandCount => 1;
}

class Relative extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final offset = cpu.read(pc);
    final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;
    return (pc + 1 + offsetSigned, false);
  }

  @override
  int get operandCount => 1;
}

class Absolute extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) => (cpu.read16(pc), false);

  @override
  int get operandCount => 2;
}

class AbsoluteX extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final address = cpu.read16(pc);
    final targetAddress = (address + cpu.X) & 0xffff;
    return (targetAddress, wasPageCrossed(address, targetAddress));
  }

  @override
  int get operandCount => 2;
}

class AbsoluteY extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final address = cpu.read16(pc);
    final targetAddress = (address + cpu.Y) & 0xffff;
    return (targetAddress, wasPageCrossed(address, targetAddress));
  }

  @override
  int get operandCount => 2;
}

class Indirect extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final address = cpu.read16(pc);
    final targetAddress = cpu.read16(address, wrap: true);
    return (targetAddress, false);
  }

  @override
  int get operandCount => 2;
}

class IndexedIndirect extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final address = (cpu.read(pc) + cpu.X) & 0xff;
    final targetAddress = cpu.read16(address, wrap: true);
    return (targetAddress, false);
  }

  @override
  int get operandCount => 1;
}

class IndirectIndexed extends AddressMode {
  @override
  (int, bool) read(CPU cpu, int pc) {
    final zeroPageAddress = cpu.read(pc);
    final address = cpu.read16(zeroPageAddress, wrap: true);
    final targetAddress = (address + cpu.Y) & 0xffff;
    return (targetAddress, wasPageCrossed(address, targetAddress));
  }

  @override
  int get operandCount => 1;
}

final implicit = Implicit();
final accumulator = Accumulator();
final immediate = Immediate();
final zeroPage = ZeroPage();
final zeroPageX = ZeroPageX();
final zeroPageY = ZeroPageY();
final relative = Relative();
final absolute = Absolute();
final absoluteX = AbsoluteX();
final absoluteY = AbsoluteY();
final indirect = Indirect();
final indexedIndirect = IndexedIndirect();
final indirectIndexed = IndirectIndexed();
