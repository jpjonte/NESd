import 'package:nesd/nes/cpu/cpu.dart';

sealed class AddressMode {
  void execute(CPU cpu);

  int get operandCount;

  int read(CPU cpu) => cpu.read(cpu.address);

  void write(CPU cpu, int value) => cpu.write(cpu.address, value);
}

bool wasPageCrossed(int from, int to) => from & 0xff00 != to & 0xff00;

class Implicit extends AddressMode {
  @override
  void execute(CPU cpu) {
    cpu.read(cpu.PC); // dummy read
  }

  @override
  int get operandCount => 0;

  @override
  int read(CPU cpu) => 0;

  @override
  void write(CPU cpu, int value) {}
}

class Accumulator extends AddressMode {
  @override
  void execute(CPU cpu) => cpu.read(cpu.PC); // dummy read

  @override
  int get operandCount => 0;

  @override
  int read(CPU cpu) => cpu.A;

  @override
  void write(CPU cpu, int value) => cpu.A = value;
}

class Immediate extends AddressMode {
  @override
  void execute(CPU cpu) {}

  @override
  int get operandCount => 1;

  @override
  int read(CPU cpu) => cpu.read(cpu.PC++);

  @override
  void write(CPU cpu, int value) {}
}

class ZeroPage extends AddressMode {
  @override
  void execute(CPU cpu) => cpu.address = cpu.read(cpu.PC++) & 0xff;

  @override
  int get operandCount => 1;
}

class ZeroPageX extends AddressMode {
  @override
  void execute(CPU cpu) {
    final zeroPageAddress = cpu.read(cpu.PC++);

    cpu
      ..read(zeroPageAddress) // dummy read
      ..address = (zeroPageAddress + cpu.X) & 0xff;
  }

  @override
  int get operandCount => 1;
}

class ZeroPageY extends AddressMode {
  @override
  void execute(CPU cpu) {
    final zeroPageAddress = cpu.read(cpu.PC++);

    cpu
      ..read(zeroPageAddress) // dummy read
      ..address = (zeroPageAddress + cpu.Y) & 0xff;
  }

  @override
  int get operandCount => 1;
}

class Relative extends AddressMode {
  @override
  void execute(CPU cpu) {
    final offset = cpu.read(cpu.PC++);
    final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;

    cpu.address = cpu.PC + offsetSigned;
  }

  @override
  int get operandCount => 1;
}

class Absolute extends AddressMode {
  @override
  void execute(CPU cpu) {
    cpu
      ..address = cpu.read16(cpu.PC)
      ..PC += 2;
  }

  @override
  int get operandCount => 2;
}

class AbsoluteX extends AddressMode {
  @override
  void execute(CPU cpu) {
    final base = cpu.read16(cpu.PC);

    cpu
      ..address = base + cpu.X
      ..PC += 2;

    if (cpu.operation.instruction.isWrite ||
        wasPageCrossed(base, cpu.address)) {
      cpu.read(cpu.address); // dummy read
    }
  }

  @override
  int get operandCount => 2;
}

class AbsoluteY extends AddressMode {
  @override
  void execute(CPU cpu) {
    final base = cpu.read16(cpu.PC);

    cpu
      ..PC += 2
      ..address = base + cpu.Y;

    if (cpu.operation.instruction.isWrite ||
        wasPageCrossed(base, cpu.address)) {
      cpu.read(cpu.address); // dummy read
    }
  }

  @override
  int get operandCount => 2;
}

class Indirect extends AddressMode {
  @override
  void execute(CPU cpu) {
    final readAddress = cpu.read16(cpu.PC);

    cpu
      ..PC += 2
      ..address = cpu.read16(readAddress, wrap: true);
  }

  @override
  int get operandCount => 2;
}

class IndexedIndirect extends AddressMode {
  @override
  void execute(CPU cpu) {
    final zeroPageAddress = cpu.read(cpu.PC++);
    final readAddress = (zeroPageAddress + cpu.X) & 0xff;

    cpu
      ..read(zeroPageAddress) // dummy read
      ..address = cpu.read16(readAddress, wrap: true);
  }

  @override
  int get operandCount => 1;
}

class IndirectIndexed extends AddressMode {
  @override
  void execute(CPU cpu) {
    final zeroPageAddress = cpu.read(cpu.PC++);

    final base = cpu.read16(zeroPageAddress, wrap: true);

    cpu.address = (base + cpu.Y) & 0xffff;

    if (cpu.operation.instruction.isWrite ||
        wasPageCrossed(base, cpu.address)) {
      cpu.read(cpu.address); // dummy read
    }
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
