// ignore_for_file: non_constant_identifier_names

import 'package:nes/address_mode.dart';
import 'package:nes/bit_extension.dart';
import 'package:nes/cpu.dart';

typedef Executor = int Function(CPU, AddressMode, int, int);

class Instruction {
  Instruction(this.name, this.execute);

  final String name;
  final Executor execute;
}

class Operation {
  Operation(
    this.instruction,
    this.addressMode,
    this.cycles, {
    this.pageCrossAddsCycle = false,
  });

  final Instruction instruction;
  final AddressMode addressMode;
  final int cycles;
  final bool pageCrossAddsCycle;

  int execute(CPU cpu) {
    final (address, value) = addressMode.read(cpu);

    final start = cpu.PC;

    final additionalCycles = instruction.execute(
      cpu,
      addressMode,
      address,
      value,
    );

    final jumped = start != cpu.PC;

    // TODO bud-27.05.24 add cycle if page crossed for applicable operations
    // if (pageCrossAddsCycle && ...) {
    //   return additionalCycles + 1;
    // }

    return additionalCycles;
  }
}

final ops = {
  0x00: Operation(BRK, implicit, 7),
  0x01: Operation(ORA, indirectIndexed, 6),
  // 0x02 .. 0x04
  0x05: Operation(ORA, zeroPage, 3),
  0x06: Operation(ASL, zeroPage, 5),
  // 0x07
  0x08: Operation(PHP, implicit, 3),
  0x09: Operation(ORA, immediate, 2),
  0x0a: Operation(ASL, accumulator, 2),
  // 0x0b .. 0x0c
  0x0d: Operation(ORA, absolute, 4),
  0x0e: Operation(ASL, absolute, 6),
  // 0x0f
  0x10: Operation(BPL, relative, 2),
  0x11: Operation(ORA, indexedIndirect, 5, pageCrossAddsCycle: true),
  // 0x12 .. 0x14
  0x15: Operation(ORA, zeroPageX, 4),
  0x16: Operation(ASL, zeroPageX, 6),
  // 0x17
  0x18: Operation(CLC, implicit, 2),
  0x19: Operation(ORA, absoluteY, 4, pageCrossAddsCycle: true),
  // 0x1a .. 0x1c
  0x1d: Operation(ORA, absoluteX, 4, pageCrossAddsCycle: true),
  0x1e: Operation(ASL, absoluteX, 7),
  // 0x1f
  0x20: Operation(JSR, absolute, 6),
  0x21: Operation(AND, indexedIndirect, 6),
  // 0x22 .. 0x23
  0x24: Operation(BIT, zeroPage, 3),
  0x25: Operation(AND, zeroPage, 3),
  0x26: Operation(ROL, zeroPage, 5),
  // 0x27
  0x28: Operation(PLP, implicit, 4),
  0x29: Operation(AND, immediate, 2),
  0x2a: Operation(ROL, accumulator, 2),
  // 0x2b
  0x2c: Operation(BIT, absolute, 4),
  0x2d: Operation(AND, absolute, 4),
  0x2e: Operation(ROL, absolute, 6),
  // 0x2f
  0x30: Operation(BMI, relative, 2),
  0x31: Operation(AND, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0x32 .. 0x34
  0x35: Operation(AND, zeroPageX, 4),
  0x36: Operation(ROL, zeroPageX, 6),
  // 0x37
  0x38: Operation(SEC, implicit, 2),
  0x39: Operation(AND, absoluteY, 4, pageCrossAddsCycle: true),
  // 0x3a .. 0x3c
  0x3d: Operation(AND, absoluteX, 4, pageCrossAddsCycle: true),
  0x3e: Operation(ROL, absoluteX, 7),
  // 0x3f
  0x40: Operation(RTI, implicit, 6),
  0x41: Operation(EOR, indirectIndexed, 6),
  // 0x42 .. 0x44
  0x45: Operation(EOR, zeroPage, 3),
  0x46: Operation(LSR, zeroPage, 5),
  // 0x47
  0x48: Operation(PHA, implicit, 3),
  0x49: Operation(EOR, immediate, 2),
  0x4a: Operation(LSR, accumulator, 2),
  // 0x4b
  0x4c: Operation(JMP, absolute, 3),
  0x4d: Operation(EOR, absolute, 4),
  0x4e: Operation(LSR, absolute, 6),
  // 0x4f
  0x50: Operation(BVC, relative, 2, pageCrossAddsCycle: true),
  0x51: Operation(EOR, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0x52 .. 0x54
  0x55: Operation(EOR, zeroPageX, 4),
  0x56: Operation(LSR, zeroPageX, 6),
  // 0x57
  0x58: Operation(CLI, implicit, 2),
  0x59: Operation(EOR, absoluteY, 4, pageCrossAddsCycle: true),
  // 0x5a .. 0x5c
  0x5d: Operation(EOR, absoluteX, 4, pageCrossAddsCycle: true),
  0x5e: Operation(LSR, absoluteX, 7),
  // 0x5f
  0x60: Operation(RTS, implicit, 6),
  0x61: Operation(ADC, indexedIndirect, 6),
  // 0x62 .. 0x64
  0x65: Operation(ADC, zeroPage, 3),
  0x66: Operation(ROR, zeroPage, 5),
  // 0x67
  0x68: Operation(PLA, implicit, 4),
  0x69: Operation(ADC, immediate, 2),
  0x6a: Operation(ROR, accumulator, 2),
  // 0x6b
  0x6c: Operation(JMP, indirect, 5),
  0x6d: Operation(ADC, absolute, 4),
  0x6e: Operation(ROR, absolute, 6),
  // 0x6f
  0x70: Operation(BVS, relative, 2, pageCrossAddsCycle: true),
  0x71: Operation(ADC, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0x72 .. 0x74
  0x75: Operation(ADC, zeroPageX, 4),
  0x76: Operation(ROR, zeroPageX, 6),
  // 0x77
  0x78: Operation(SEI, implicit, 2),
  0x79: Operation(ADC, absoluteY, 4, pageCrossAddsCycle: true),
  // 0x7a .. 0x7c
  0x7d: Operation(ADC, absoluteX, 4, pageCrossAddsCycle: true),
  0x7e: Operation(ROR, absoluteX, 7),
  // 0x7f .. 0x80
  0x81: Operation(STA, indexedIndirect, 6),
  // 0x82 .. 0x83
  0x84: Operation(STY, zeroPage, 3),
  0x85: Operation(STA, zeroPage, 3),
  0x86: Operation(STX, zeroPage, 3),
  // 0x87
  0x88: Operation(DEY, implicit, 2),
  // 0x89
  0x8a: Operation(TXA, implicit, 2),
  // 0x8b
  0x8c: Operation(STY, absolute, 4),
  0x8d: Operation(STA, absolute, 4),
  0x8e: Operation(STX, absolute, 4),
  // 0x8f
  0x90: Operation(BCC, relative, 2, pageCrossAddsCycle: true),
  0x91: Operation(STA, indirectIndexed, 6),
  // 0x92 .. 0x93
  0x94: Operation(STY, zeroPageX, 4),
  0x95: Operation(STA, zeroPageX, 4),
  0x96: Operation(STX, zeroPageY, 4),
  // 0x97
  0x98: Operation(TYA, implicit, 2),
  0x99: Operation(STA, absoluteY, 5),
  0x9a: Operation(TXS, implicit, 2),
  // 0x9b .. 0x9c
  0x9d: Operation(STA, absoluteX, 5),
  // 0x9e .. 0x9f
  0xa0: Operation(LDY, immediate, 2),
  0xa1: Operation(LDA, indexedIndirect, 6),
  0xa2: Operation(LDX, immediate, 2),
  // 0xa3
  0xa4: Operation(LDY, zeroPage, 3),
  0xa5: Operation(LDA, zeroPage, 3),
  0xa6: Operation(LDX, zeroPage, 3),
  // 0xa7
  0xa8: Operation(TAY, implicit, 2),
  0xa9: Operation(LDA, immediate, 2),
  0xaa: Operation(TAX, implicit, 2),
  // 0xab
  0xac: Operation(LDY, absolute, 4),
  0xad: Operation(LDA, absolute, 4),
  0xae: Operation(LDX, absolute, 4),
  // 0xaf
  0xb0: Operation(BCS, relative, 2, pageCrossAddsCycle: true),
  0xb1: Operation(LDA, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0xb2 .. 0xb3
  0xb4: Operation(LDY, zeroPageX, 4),
  0xb5: Operation(LDA, zeroPageX, 4),
  0xb6: Operation(LDX, zeroPageY, 4),
  // 0xb7
  0xb8: Operation(CLV, implicit, 2),
  0xb9: Operation(LDA, absoluteY, 4, pageCrossAddsCycle: true),
  0xba: Operation(TSX, implicit, 2),
  // 0xbb
  0xbc: Operation(LDY, absoluteX, 4, pageCrossAddsCycle: true),
  0xbd: Operation(LDA, absoluteX, 4, pageCrossAddsCycle: true),
  0xbe: Operation(LDX, absoluteY, 4, pageCrossAddsCycle: true),
  // 0xbf
  0xc0: Operation(CPY, immediate, 2),
  0xc1: Operation(CMP, indexedIndirect, 6),
  // 0xc2 .. 0xc3
  0xc4: Operation(CPY, zeroPage, 3),
  0xc5: Operation(CMP, zeroPage, 3),
  0xc6: Operation(DEC, zeroPage, 5),
  // 0xc7
  0xc8: Operation(INY, implicit, 2),
  0xc9: Operation(CMP, immediate, 2),
  0xca: Operation(DEX, implicit, 2),
  // 0xcb
  0xcc: Operation(CPY, absolute, 4),
  0xcd: Operation(CMP, absolute, 4),
  0xce: Operation(DEC, absolute, 6),
  // 0xcf
  0xd0: Operation(BNE, relative, 2, pageCrossAddsCycle: true),
  0xd1: Operation(CMP, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0xd2 .. 0xd4
  0xd5: Operation(CMP, zeroPageX, 4),
  0xd6: Operation(DEC, zeroPageX, 6),
  // 0xd7
  0xd8: Operation(CLD, implicit, 2),
  0xd9: Operation(CMP, absoluteY, 4, pageCrossAddsCycle: true),
  // 0xda .. 0xdc
  0xdd: Operation(CMP, absoluteX, 4, pageCrossAddsCycle: true),
  0xde: Operation(DEC, absoluteX, 7),
  // 0xdf
  0xe0: Operation(CPX, immediate, 2),
  0xe1: Operation(SBC, indexedIndirect, 6),
  // 0xe2 .. 0xe3
  0xe4: Operation(CPX, zeroPage, 3),
  0xe5: Operation(SBC, zeroPage, 3),
  0xe6: Operation(INC, zeroPage, 5),
  // 0xe7
  0xe8: Operation(INX, implicit, 2),
  0xe9: Operation(SBC, immediate, 2),
  0xea: Operation(NOP, implicit, 2),
  // 0xeb
  0xec: Operation(CPX, absolute, 4),
  0xed: Operation(SBC, absolute, 4),
  0xee: Operation(INC, absolute, 6),
  // 0xef
  0xf0: Operation(BEQ, relative, 2, pageCrossAddsCycle: true),
  0xf1: Operation(SBC, indirectIndexed, 5, pageCrossAddsCycle: true),
  // 0xf2 .. 0xf4
  0xf5: Operation(SBC, zeroPageX, 4),
  0xf6: Operation(INC, zeroPageX, 6),
  // 0xf7
  0xf8: Operation(SED, implicit, 2),
  0xf9: Operation(SBC, absoluteY, 4, pageCrossAddsCycle: true),
  // 0xfa .. 0xfc
  0xfd: Operation(SBC, absoluteX, 4, pageCrossAddsCycle: true),
  0xfe: Operation(INC, absoluteX, 7),
  // 0xff
};

int calculateBranchCycles(int from, int to, int value) {
  if (from & 0xff00 != to & 0xff00) {
    // page crossed
    return 2;
  }

  return 1;
}

final BRK = Instruction('BRK', (cpu, mode, address, value) {
  cpu
    ..pushStack16(cpu.PC)
    ..pushStack(cpu.P)
    ..B = 1
    ..PC = cpu.read(0xfffe) | (cpu.read(0xffff) << 8);

  return 0;
});

final ORA = Instruction('ORA', (cpu, mode, address, value) {
  cpu
    ..A |= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A & 0x80 == 0 ? 0 : 1;

  return 0;
});

final ASL = Instruction('ASL', (cpu, mode, address, value) {
  final result = value << 1;

  cpu
    ..C = value.bit(7)
    ..Z = value == 0 ? 1 : 0
    ..N = result.bit(7);

  if (mode == accumulator) {
    cpu.A = result;
  } else {
    cpu.write(address, result);
  }

  return 0;
});

final PHP = Instruction('PHP', (cpu, mode, address, value) {
  cpu.pushStack(cpu.P);

  return 0;
});

final BPL = Instruction('BPL', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.N == 0) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final CLC = Instruction('CLC', (cpu, mode, address, value) {
  cpu.C = 0;

  return 0;
});

final JSR = Instruction('JSR', (cpu, mode, address, value) {
  cpu
    ..pushStack16(cpu.PC - 1)
    ..PC = address;

  return 0;
});

final AND = Instruction('AND', (cpu, mode, address, value) {
  cpu
    ..A &= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);

  return 0;
});

final BIT = Instruction('BIT', (cpu, mode, address, value) {
  final result = cpu.A & value;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..V = value.bit(6)
    ..N = value.bit(7);

  return 0;
});

final ROL = Instruction('ROL', (cpu, mode, address, value) {
  final result = (value << 1) | cpu.C;

  cpu.C = value.bit(7);

  if (mode == accumulator) {
    cpu.A = result;
  } else {
    cpu.write(address, result);
  }

  return 0;
});

final PLP = Instruction('PLP', (cpu, mode, address, value) {
  cpu.P = cpu.popStack();

  return 0;
});

final BMI = Instruction('BMI', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.N == 1) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final SEC = Instruction('SEC', (cpu, mode, address, value) {
  cpu.C = 1;

  return 0;
});

final RTI = Instruction('RTI', (cpu, mode, address, value) {
  cpu
    ..P = cpu.popStack()
    ..PC = cpu.popStack16();

  return 0;
});

final EOR = Instruction('EOR', (cpu, mode, address, value) {
  cpu
    ..A ^= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);

  return 0;
});

final LSR = Instruction('LSR', (cpu, mode, address, value) {
  final result = value >> 1;

  cpu
    ..C = value.bit(0)
    ..Z = result == 0 ? 1 : 0
    ..N = 0;

  if (mode == accumulator) {
    cpu.A = result;
  } else {
    cpu.write(address, result);
  }

  return 0;
});

final PHA = Instruction('PHA', (cpu, mode, address, value) {
  cpu.pushStack(cpu.A);

  return 0;
});

final JMP = Instruction('JMP', (cpu, mode, address, value) {
  cpu.PC = address;

  return 0;
});

final BVC = Instruction('BVC', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.V == 0) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final CLI = Instruction('CLI', (cpu, mode, address, value) {
  cpu.I = 0;

  return 0;
});

final RTS = Instruction('RTS', (cpu, mode, address, value) {
  cpu.PC = cpu.popStack16() + 1;

  return 0;
});

final ADC = Instruction('ADC', (cpu, mode, address, value) {
  final result = cpu.A + value + cpu.C;

  cpu
    ..C = result > 0xff ? 1 : 0
    ..Z = result & 0xff == 0 ? 1 : 0
    // TODO bud-27.05.24 check this
    ..V = (~(cpu.A ^ value) & (cpu.A ^ result) & 0x80) != 0 ? 1 : 0
    ..N = result.bit(7)
    ..A = result & 0xff;

  return 0;
});

final ROR = Instruction('ROR', (cpu, mode, address, value) {
  final result = (value >> 1) | (cpu.C << 7);

  cpu
    ..C = value.bit(0)
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);

  if (mode == accumulator) {
    cpu.A = result;
  } else {
    cpu.write(address, result);
  }

  return 0;
});

final PLA = Instruction('PLA', (cpu, mode, address, value) {
  final result = cpu.popStack();

  cpu
    ..A = result
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);

  return 0;
});

final BVS = Instruction('BVS', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.V == 1) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final SEI = Instruction('SEI', (cpu, mode, address, value) {
  cpu.I = 1;

  return 0;
});

final STA = Instruction('STA', (cpu, mode, address, value) {
  cpu.write(address, cpu.A);

  return 0;
});

final STY = Instruction('STY', (cpu, mode, address, value) {
  cpu.write(address, cpu.Y);

  return 0;
});

final STX = Instruction('STX', (cpu, mode, address, value) {
  cpu.write(address, cpu.X);

  return 0;
});

final DEY = Instruction('DEY', (cpu, mode, address, value) {
  cpu
    ..Y = (cpu.Y - 1) & 0xff
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);

  return 0;
});

final TXA = Instruction('TXA', (cpu, mode, address, value) {
  cpu
    ..A = cpu.X
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);

  return 0;
});

final BCC = Instruction('BCC', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.C == 0) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final TYA = Instruction('TYA', (cpu, mode, address, value) {
  cpu
    ..A = cpu.Y
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);

  return 0;
});

final TXS = Instruction('TXS', (cpu, mode, address, value) {
  cpu.SP = cpu.X;

  return 0;
});

final LDY = Instruction('LDY', (cpu, mode, address, value) {
  cpu
    ..Y = value
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);

  return 0;
});

final LDA = Instruction('LDA', (cpu, mode, address, value) {
  cpu
    ..A = value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);

  return 0;
});

final LDX = Instruction('LDX', (cpu, mode, address, value) {
  cpu
    ..X = value
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);

  return 0;
});

final TAY = Instruction('TAY', (cpu, mode, address, value) {
  cpu
    ..Y = cpu.A
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);

  return 0;
});

final TAX = Instruction('TAX', (cpu, mode, address, value) {
  cpu
    ..X = cpu.A
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);

  return 0;
});

final BCS = Instruction('BCS', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.C == 1) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final CLV = Instruction('CLV', (cpu, mode, address, value) {
  cpu.V = 0;

  return 0;
});

final TSX = Instruction('TSX', (cpu, mode, address, value) {
  cpu
    ..X = cpu.SP
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);

  return 0;
});

final CPY = Instruction('CPY', (cpu, mode, address, value) {
  final result = cpu.Y - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);

  return 0;
});

final CMP = Instruction('CMP', (cpu, mode, address, value) {
  final result = cpu.A - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);

  return 0;
});

final DEC = Instruction('DEC', (cpu, mode, address, value) {
  final result = (value - 1) & 0xff;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);

  return 0;
});

final INY = Instruction('INY', (cpu, mode, address, value) {
  cpu
    ..Y = (cpu.Y + 1) & 0xff
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);

  return 0;
});

final DEX = Instruction('DEX', (cpu, mode, address, value) {
  cpu
    ..X = (cpu.X - 1) & 0xff
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);

  return 0;
});

final BNE = Instruction('BNE', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.Z == 0) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final CLD = Instruction('CLD', (cpu, mode, address, value) {
  cpu.D = 0;

  return 0;
});

final CPX = Instruction('CPX', (cpu, mode, address, value) {
  final result = cpu.X - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);

  return 0;
});

final SBC = Instruction('SBC', (cpu, mode, address, value) {
  final result = cpu.A - value - (1 - cpu.C);

  cpu
    // TODO bud-28.05.24 check this
    ..C = result >= 0 ? 1 : 0
    ..Z = result & 0xff == 0 ? 1 : 0
    // TODO bud-27.05.24 check this
    ..V = ((cpu.A ^ result) & (cpu.A ^ value) & 0x80) != 0 ? 1 : 0
    ..N = result.bit(7)
    ..A = result & 0xff;

  return 0;
});

final INC = Instruction('INC', (cpu, mode, address, value) {
  final result = (value + 1) & 0xff;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);

  return 0;
});

final INX = Instruction('INX', (cpu, mode, address, value) {
  cpu
    ..X = (cpu.X + 1) & 0xff
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);

  return 0;
});

final NOP = Instruction('NOP', (cpu, mode, address, value) => 0);

final BEQ = Instruction('BEQ', (cpu, mode, address, value) {
  final start = cpu.PC;

  if (cpu.Z == 1) {
    cpu.PC = address;

    return calculateBranchCycles(start, address, value);
  }

  return 0;
});

final SED = Instruction('SED', (cpu, mode, address, value) {
  cpu.D = 1;

  return 0;
});
