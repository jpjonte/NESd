// ignore_for_file: non_constant_identifier_names

import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/cpu/cpu.dart';

enum InstructionType {
  jump,
  branch,
  other,
}

typedef Executor = void Function(CPU, int);

class Instruction {
  Instruction(
    this.name,
    this.execute, {
    this.type = InstructionType.other,
  });

  final String name;
  final Executor execute;
  final InstructionType type;
}

final BRK = Instruction('BRK', (cpu, address) {
  cpu
    ..pushStack16(cpu.PC)
    ..pushStack(cpu.P.setBit(4, 1))
    ..I = 1
    ..PC = cpu.read16(0xfffe);
});

final ORA = Instruction('ORA', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..A |= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A & 0x80 == 0 ? 0 : 1;
});

final ASL = Instruction('ASL', (cpu, address) {
  final value = cpu.read(address);
  final result = (value << 1) & 0xff;

  cpu
    ..C = value.bit(7)
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);
});

final PHP = Instruction(
  'PHP',
  (cpu, address) => cpu.pushStack(cpu.P.setBit(4, 1)),
);

final BPL = Instruction(
  'BPL',
  (cpu, address) {
    if (cpu.N == 0) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final CLC = Instruction('CLC', (cpu, address) => cpu.C = 0);

final JSR = Instruction(
  'JSR',
  (cpu, address) {
    cpu
      ..pushStack16(cpu.PC - 1)
      ..PC = address;
  },
  type: InstructionType.jump,
);

final AND = Instruction('AND', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..A &= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);
});

final BIT = Instruction('BIT', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.A & value;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..V = value.bit(6)
    ..N = value.bit(7);
});

final ROL = Instruction('ROL', (cpu, address) {
  final value = cpu.read(address);

  final result = ((value << 1) | cpu.C) & 0xff;

  cpu
    ..C = value.bit(7)
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);
});

final PLP = Instruction('PLP', (cpu, address) {
  final result = cpu.popStack();

  cpu
    ..C = result.bit(0)
    ..Z = result.bit(1)
    ..I = result.bit(2)
    ..D = result.bit(3)
    ..V = result.bit(6)
    ..N = result.bit(7);
});

final BMI = Instruction(
  'BMI',
  (cpu, address) {
    if (cpu.N == 1) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final SEC = Instruction('SEC', (cpu, address) => cpu.C = 1);

final RTI = Instruction('RTI', (cpu, address) {
  cpu
    ..P = cpu.popStack().setBit(5, 1)
    ..PC = cpu.popStack16();
});

final EOR = Instruction('EOR', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..A ^= value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);
});

final LSR = Instruction('LSR', (cpu, address) {
  final value = cpu.read(address);
  final result = value >> 1;

  cpu
    ..C = value.bit(0)
    ..Z = result == 0 ? 1 : 0
    ..N = 0
    ..write(address, result);
});

final PHA = Instruction(
  'PHA',
  (cpu, address) => cpu.pushStack(cpu.A),
);

final JMP = Instruction(
  'JMP',
  (cpu, address) => cpu.PC = address,
  type: InstructionType.jump,
);

final BVC = Instruction(
  'BVC',
  (cpu, address) {
    if (cpu.V == 0) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final CLI = Instruction('CLI', (cpu, address) => cpu.I = 0);

final RTS = Instruction(
  'RTS',
  (cpu, address) => cpu.PC = cpu.popStack16() + 1,
);

final ADC = Instruction('ADC', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.A + value + cpu.C;

  cpu
    ..C = result > 0xff ? 1 : 0
    ..Z = result & 0xff == 0 ? 1 : 0
    ..V = (~(cpu.A ^ value) & (cpu.A ^ result) & 0x80) != 0 ? 1 : 0
    ..N = result.bit(7)
    ..A = result & 0xff;
});

final ROR = Instruction('ROR', (cpu, address) {
  final value = cpu.read(address);
  final result = (value >> 1) | (cpu.C << 7);

  cpu
    ..C = value.bit(0)
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);
});

final PLA = Instruction('PLA', (cpu, address) {
  final result = cpu.popStack();

  cpu
    ..A = result
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);
});

final BVS = Instruction(
  'BVS',
  (cpu, address) {
    if (cpu.V == 1) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final SEI = Instruction('SEI', (cpu, address) => cpu.I = 1);

final STA = Instruction('STA', (cpu, address) => cpu.write(address, cpu.A));

final STY = Instruction('STY', (cpu, address) => cpu.write(address, cpu.Y));

final STX = Instruction('STX', (cpu, address) => cpu.write(address, cpu.X));

final DEY = Instruction('DEY', (cpu, address) {
  cpu
    ..Y = (cpu.Y - 1) & 0xff
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);
});

final TXA = Instruction('TXA', (cpu, address) {
  cpu
    ..A = cpu.X
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);
});

final BCC = Instruction(
  'BCC',
  (cpu, address) {
    if (cpu.C == 0) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final TYA = Instruction('TYA', (cpu, address) {
  cpu
    ..A = cpu.Y
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);
});

final TXS = Instruction('TXS', (cpu, address) => cpu.SP = cpu.X);

final LDY = Instruction('LDY', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..Y = value
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);
});

final LDA = Instruction('LDA', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..A = value
    ..Z = cpu.A == 0 ? 1 : 0
    ..N = cpu.A.bit(7);
});

final LDX = Instruction('LDX', (cpu, address) {
  final value = cpu.read(address);

  cpu
    ..X = value
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);
});

final TAY = Instruction('TAY', (cpu, address) {
  cpu
    ..Y = cpu.A
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);
});

final TAX = Instruction('TAX', (cpu, address) {
  cpu
    ..X = cpu.A
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);
});

final BCS = Instruction(
  'BCS',
  (cpu, address) {
    if (cpu.C == 1) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final CLV = Instruction('CLV', (cpu, address) => cpu.V = 0);

final TSX = Instruction('TSX', (cpu, address) {
  cpu
    ..X = cpu.SP
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);
});

final CPY = Instruction('CPY', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.Y - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);
});

final CMP = Instruction('CMP', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.A - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);
});

final DEC = Instruction('DEC', (cpu, address) {
  final value = cpu.read(address);
  final result = (value - 1) & 0xff;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);
});

final INY = Instruction('INY', (cpu, address) {
  cpu
    ..Y = (cpu.Y + 1) & 0xff
    ..Z = cpu.Y == 0 ? 1 : 0
    ..N = cpu.Y.bit(7);
});

final DEX = Instruction('DEX', (cpu, address) {
  cpu
    ..X = (cpu.X - 1) & 0xff
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);
});

final BNE = Instruction(
  'BNE',
  (cpu, address) {
    if (cpu.Z == 0) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final CLD = Instruction('CLD', (cpu, address) => cpu.D = 0);

final CPX = Instruction('CPX', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.X - value;

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7);
});

final SBC = Instruction('SBC', (cpu, address) {
  final value = cpu.read(address);
  final result = cpu.A - value - (1 - cpu.C);

  cpu
    ..C = result >= 0 ? 1 : 0
    ..Z = result & 0xff == 0 ? 1 : 0
    ..V = ((cpu.A ^ result) & (cpu.A ^ value) & 0x80) != 0 ? 1 : 0
    ..N = result.bit(7)
    ..A = result & 0xff;
});

final INC = Instruction('INC', (cpu, address) {
  final value = cpu.read(address);
  final result = (value + 1) & 0xff;

  cpu
    ..Z = result == 0 ? 1 : 0
    ..N = result.bit(7)
    ..write(address, result);
});

final INX = Instruction('INX', (cpu, address) {
  cpu
    ..X = (cpu.X + 1) & 0xff
    ..Z = cpu.X == 0 ? 1 : 0
    ..N = cpu.X.bit(7);
});

final NOP = Instruction('NOP', (cpu, address) {});

final BEQ = Instruction(
  'BEQ',
  (cpu, address) {
    if (cpu.Z == 1) {
      cpu.PC = address;
    }
  },
  type: InstructionType.branch,
);

final SED = Instruction('SED', (cpu, address) => cpu.D = 1);

final LAX = Instruction('LAX', (cpu, address) {
  LDA.execute(cpu, address);
  LDX.execute(cpu, address);
});

final SAX = Instruction(
  'SAX',
  (cpu, address) => cpu.write(address, cpu.A & cpu.X),
);

final DCP = Instruction('DCP', (cpu, address) {
  DEC.execute(cpu, address);
  CMP.execute(cpu, address);
});

final ISC = Instruction('ISB', (cpu, address) {
  INC.execute(cpu, address);
  SBC.execute(cpu, address);
});

final SLO = Instruction('SLO', (cpu, address) {
  ASL.execute(cpu, address);
  ORA.execute(cpu, address);
});

final RLA = Instruction('RLA', (cpu, address) {
  ROL.execute(cpu, address);
  AND.execute(cpu, address);
});

final SRE = Instruction('SRE', (cpu, address) {
  LSR.execute(cpu, address);
  EOR.execute(cpu, address);
});

final RRA = Instruction('RRA', (cpu, address) {
  ROR.execute(cpu, address);
  ADC.execute(cpu, address);
});
