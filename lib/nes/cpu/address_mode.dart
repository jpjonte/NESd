import 'package:nesd/nes/cpu/cpu.dart';

typedef Reader = void Function(CPU);
typedef Writer = void Function(CPU, int, {bool dummy});

sealed class AddressMode {
  List<CpuCycle> pipeline({required bool read, required bool write});

  int get operandCount;

  CpuCycle get preInstruction => (cpu) {};

  Writer get writer {
    return (cpu, value, {bool dummy = false}) {
      cpu.prependCycles([
        if (dummy) (cpu) => cpu.write(cpu.address, cpu.operand),
        (cpu) => cpu.write(cpu.address, value),
      ]);
    };
  }
}

bool wasPageCrossed(int from, int to) => from & 0xff00 != to & 0xff00;

class Implicit extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) => [
    (cpu) => cpu.read(cpu.PC), // dummy read
  ];

  @override
  int get operandCount => 0;

  @override
  Writer get writer => (_, _, {dummy = false}) {};
}

class Accumulator extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) => [];

  @override
  int get operandCount => 0;

  @override
  CpuCycle get preInstruction => (cpu) => cpu.operand = cpu.A;

  @override
  Writer get writer => (cpu, value, {dummy = false}) => cpu.A = value;
}

class Immediate extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) => [
    if (read) (cpu) => cpu.operand = cpu.read(cpu.PC++),
  ];

  @override
  int get operandCount => 1;

  @override
  Writer get writer => (_, _, {dummy = false}) {};
}

class ZeroPage extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) => [
    (cpu) => cpu.address = cpu.read(cpu.PC++) & 0xff,
    if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
  ];

  @override
  int get operandCount => 1;
}

class ZeroPageX extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var base = 0;

    return [
      (cpu) => base = cpu.read(cpu.PC++),
      (cpu) {
        cpu
          ..read(base)
          ..address = (base + cpu.X) & 0xff;
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 1;
}

class ZeroPageY extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var base = 0;

    return [
      (cpu) => base = cpu.read(cpu.PC++),
      (cpu) {
        cpu
          ..read(base)
          ..address = (base + cpu.Y) & 0xff;
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 1;
}

class Relative extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    return [
      (cpu) {
        final offset = cpu.read(cpu.PC++);
        final offsetSigned = offset >= 0x80 ? offset - 0x100 : offset;

        cpu.address = cpu.PC + offsetSigned;
      },
    ];
  }

  @override
  int get operandCount => 1;
}

class Absolute extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var addressLow = 0;

    return [
      (cpu) => addressLow = cpu.read(cpu.PC++),
      (cpu) => cpu.address = cpu.read(cpu.PC++) << 8 | addressLow,
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 2;
}

class AbsoluteX extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var addressLow = 0;

    return [
      (cpu) => addressLow = cpu.read(cpu.PC++),
      (cpu) {
        final base = cpu.read(cpu.PC++) << 8 | addressLow;

        cpu.address = base + cpu.X;

        if (write || wasPageCrossed(base, cpu.address)) {
          cpu.prependCycles([(cpu) => cpu.read(cpu.address)]); // dummy read
        }
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 2;
}

class AbsoluteY extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var addressLow = 0;

    return [
      (cpu) => addressLow = cpu.read(cpu.PC++),
      (cpu) {
        final base = cpu.read(cpu.PC++) << 8 | addressLow;

        cpu.address = base + cpu.Y;

        if (write || wasPageCrossed(base, cpu.address)) {
          cpu.prependCycles([(cpu) => cpu.read(cpu.address)]); // dummy read
        }
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 2;
}

class Indirect extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var readAddressLow = 0;
    var readAddress = 0;
    var addressLow = 0;

    return [
      (cpu) => readAddressLow = cpu.read(cpu.PC++),
      (cpu) => readAddress = (cpu.read(cpu.PC++) << 8) | readAddressLow,
      (cpu) => addressLow = cpu.read(readAddress),
      (cpu) {
        final addressHigh = cpu.readHighByte(readAddress, wrap: true);

        cpu.address = (addressHigh << 8) | addressLow;
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 2;
}

class IndexedIndirect extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var baseAddress = 0;
    var readAddress = 0;
    var addressLow = 0;

    return [
      (cpu) {
        baseAddress = cpu.read(cpu.PC++);
        readAddress = (baseAddress + cpu.X) & 0xff;
      },
      (cpu) => cpu.read(readAddress), // dummy read
      (cpu) => addressLow = cpu.read(readAddress),
      (cpu) {
        final addressHigh = cpu.readHighByte(readAddress, wrap: true);

        cpu.address = (addressHigh << 8) | addressLow;
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
  }

  @override
  int get operandCount => 1;
}

class IndirectIndexed extends AddressMode {
  @override
  List<CpuCycle> pipeline({required bool read, required bool write}) {
    var readAddress = 0;
    var baseLow = 0;

    return [
      (cpu) => readAddress = cpu.read(cpu.PC++),
      (cpu) => baseLow = cpu.read(readAddress),
      (cpu) {
        final baseHigh = cpu.readHighByte(readAddress, wrap: true);
        final base = (baseHigh << 8) | baseLow;

        cpu.address = (base + cpu.Y) & 0xffff;

        if (write || wasPageCrossed(base, cpu.address)) {
          cpu.prependCycles([(cpu) => cpu.read(cpu.address)]); // dummy read
        }
      },
      if (read) (cpu) => cpu.operand = cpu.read(cpu.address),
    ];
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
