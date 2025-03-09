// instruction names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'package:nesd/exception/stop.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu.dart';

enum InstructionType { jump, branch, other }

class Instruction {
  Instruction(
    this.name,
    this.pipeline, {
    this.isRead = false,
    this.isWrite = false,
    this.merge = false,
    this.type = InstructionType.other,
  });

  final String name;
  final List<CpuCycle> Function(void Function(CPU, int, {bool dummy})) pipeline;
  final InstructionType type;
  final bool isRead;
  final bool isWrite;
  final bool merge;
}

final BRK = Instruction('BRK', (write) {
  var low = 0;
  var address = 0;

  return [
    (cpu) {
      cpu
        ..read(cpu.PC)
        ..callStack.add(cpu.PC + 1);
    },
    (cpu) => cpu.pushStack((cpu.PC + 1) >> 8),
    (cpu) => cpu.pushStack((cpu.PC + 1) & 0xff),
    (cpu) => cpu.pushStack(cpu.P.setBit(4, 1).setBit(5, 1)),
    (cpu) {
      if (cpu.doNmi) {
        cpu.doNmi = false;

        address = nmiVector;
      } else {
        address = irqVector;
      }

      cpu.I = 1;

      low = cpu.read(address);
    },
    (cpu) => cpu.PC = (cpu.readHighByte(address) << 8) | low,
  ];
}, merge: true);

final ORA = Instruction(
  'ORA',
  (write) => [
    (cpu) {
      cpu
        ..A |= cpu.operand
        ..zero(cpu.A)
        ..negative(cpu.A);
    },
  ],
  isRead: true,
  merge: true,
);

final ASL = Instruction(
  'ASL',
  (write) {
    return [
      (cpu) {
        final result = (cpu.operand << 1) & 0xff;

        cpu
          ..C = cpu.operand.bit(7)
          ..zero(result)
          ..negative(result);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final PHP = Instruction(
  'PHP',
  (write) => [(cpu) => cpu.pushStack(cpu.P.setBit(4, 1))],
);

final BPL = Instruction(
  'BPL',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.N == 0)],
  type: InstructionType.branch,
  merge: true,
);

final CLC = Instruction('CLC', (write) => [(cpu) => cpu.C = 0], merge: true);

final JSR = Instruction(
  'JSR',
  (write) => [
    (cpu) => cpu.read(cpu.PC), // dummy read
    (cpu) => cpu.pushStack((cpu.PC - 1) >> 8),
    (cpu) {
      cpu
        ..pushStack((cpu.PC - 1) & 0xff)
        ..PC = cpu.address;
    },
  ],
  type: InstructionType.jump,
);

final AND = Instruction(
  'AND',
  (write) => [
    (cpu) {
      cpu
        ..A &= cpu.operand
        ..zero(cpu.A)
        ..negative(cpu.A);
    },
  ],
  isRead: true,
  merge: true,
);

final BIT = Instruction(
  'BIT',
  (write) => [
    (cpu) {
      final result = cpu.A & cpu.operand;

      cpu
        ..zero(result)
        ..V = cpu.operand.bit(6)
        ..negative(cpu.operand);
    },
  ],
  isRead: true,
  merge: true,
);

final ROL = Instruction(
  'ROL',
  (write) {
    return [
      (cpu) {
        final result = ((cpu.operand << 1) | cpu.C) & 0xff;

        cpu
          ..C = cpu.operand.bit(7)
          ..zero(result)
          ..negative(result);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final PLP = Instruction(
  'PLP',
  (write) => [
    (cpu) => cpu.read(cpu.PC),
    (cpu) {
      final result = cpu.popStack();

      cpu
        ..C = result.bit(0)
        ..Z = result.bit(1)
        ..I = result.bit(2)
        ..D = result.bit(3)
        ..V = result.bit(6)
        ..negative(result);
    },
  ],
);

final BMI = Instruction(
  'BMI',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.N == 1)],
  type: InstructionType.branch,
  merge: true,
);

final SEC = Instruction('SEC', (write) => [(cpu) => cpu.C = 1], merge: true);

final RTI = Instruction('RTI', (write) {
  var pcLow = 0;

  return [
    (cpu) => cpu.read(cpu.PC),
    (cpu) => cpu.P = cpu.popStack().setBit(5, 1),
    (cpu) => pcLow = cpu.popStack(),
    (cpu) => cpu.PC = (cpu.popStack() << 8) | pcLow,
  ];
});

final EOR = Instruction(
  'EOR',
  (write) => [
    (cpu) {
      cpu
        ..A ^= cpu.operand
        ..zero(cpu.A)
        ..negative(cpu.A);
    },
  ],
  isRead: true,
  merge: true,
);

final LSR = Instruction(
  'LSR',
  (write) {
    return [
      (cpu) {
        final result = cpu.operand >> 1;

        cpu
          ..C = cpu.operand.bit(0)
          ..zero(result)
          ..N = 0;

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final PHA = Instruction('PHA', (write) => [(cpu) => cpu.pushStack(cpu.A)]);

final JMP = Instruction(
  'JMP',
  (write) => [(cpu) => cpu.PC = cpu.address],
  type: InstructionType.jump,
  merge: true,
);

final BVC = Instruction(
  'BVC',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.V == 0)],
  type: InstructionType.branch,
  merge: true,
);

final CLI = Instruction('CLI', (write) => [(cpu) => cpu.I = 0], merge: true);

final RTS = Instruction('RTS', (write) {
  var pcLow = 0;
  var target = 0;

  return [
    (cpu) => pcLow = cpu.popStack(),
    (cpu) => target = ((cpu.popStack() << 8) | pcLow) + 1,
    (cpu) => cpu.read(cpu.PC),
    (cpu) {
      cpu
        ..read(cpu.PC)
        ..PC = target;
    },
  ];
});

final ADC = Instruction(
  'ADC',
  (write) => [
    (cpu) {
      final result = cpu.A + cpu.operand + cpu.C;
      final maskedResult = result & 0xff;

      cpu
        ..C = result > 0xff ? 1 : 0
        ..zero(maskedResult)
        ..V = (~(cpu.A ^ cpu.operand) & (cpu.A ^ result) & 0x80) != 0 ? 1 : 0
        ..negative(result)
        ..A = maskedResult;
    },
  ],
  isRead: true,
  merge: true,
);

final ROR = Instruction(
  'ROR',
  (write) {
    return [
      (cpu) {
        final result = (cpu.operand >> 1) | (cpu.C << 7);

        cpu
          ..C = cpu.operand.bit(0)
          ..zero(result)
          ..negative(result);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final PLA = Instruction(
  'PLA',
  (write) => [
    (cpu) => cpu.read(cpu.PC), // dummy read
    (cpu) {
      final result = cpu.popStack();

      cpu
        ..A = result
        ..zero(result)
        ..negative(result);
    },
  ],
);

final BVS = Instruction(
  'BVS',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.V == 1)],
  type: InstructionType.branch,
  merge: true,
);

final SEI = Instruction('SEI', (write) => [(cpu) => cpu.I = 1], merge: true);

final STA = Instruction(
  'STA',
  (write) => [(cpu) => write(cpu, cpu.A)],
  isWrite: true,
  merge: true,
);

final STY = Instruction(
  'STY',
  (write) => [(cpu) => write(cpu, cpu.Y)],
  isWrite: true,
  merge: true,
);

final STX = Instruction(
  'STX',
  (write) => [(cpu) => write(cpu, cpu.X)],
  isWrite: true,
  merge: true,
);

final DEY = Instruction(
  'DEY',
  (write) => [
    (cpu) =>
        cpu
          ..Y = (cpu.Y - 1) & 0xff
          ..zero(cpu.Y)
          ..negative(cpu.Y),
  ],
  merge: true,
);

final TXA = Instruction(
  'TXA',
  (write) => [
    (cpu) =>
        cpu
          ..A = cpu.X
          ..zero(cpu.A)
          ..negative(cpu.A),
  ],
  merge: true,
);

final BCC = Instruction(
  'BCC',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.C == 0)],
  type: InstructionType.branch,
  merge: true,
);

final TYA = Instruction(
  'TYA',
  (write) => [
    (cpu) =>
        cpu
          ..A = cpu.Y
          ..zero(cpu.A)
          ..negative(cpu.A),
  ],
  merge: true,
);

final TXS = Instruction(
  'TXS',
  (write) => [(cpu) => cpu.SP = cpu.X],
  merge: true,
);

final LDY = Instruction(
  'LDY',
  (write) => [
    (cpu) {
      cpu
        ..Y = cpu.operand
        ..zero(cpu.Y)
        ..negative(cpu.Y);
    },
  ],
  isRead: true,
  merge: true,
);

final LDA = Instruction(
  'LDA',
  (write) => [
    (cpu) {
      cpu
        ..A = cpu.operand
        ..zero(cpu.A)
        ..negative(cpu.A);
    },
  ],
  isRead: true,
  merge: true,
);

final LDX = Instruction(
  'LDX',
  (write) => [
    (cpu) {
      cpu
        ..X = cpu.operand
        ..zero(cpu.X)
        ..negative(cpu.X);
    },
  ],
  isRead: true,
  merge: true,
);

final TAY = Instruction(
  'TAY',
  (write) => [
    (cpu) =>
        cpu
          ..Y = cpu.A
          ..zero(cpu.Y)
          ..negative(cpu.Y),
  ],
  merge: true,
);

final TAX = Instruction(
  'TAX',
  (write) => [
    (cpu) =>
        cpu
          ..X = cpu.A
          ..zero(cpu.X)
          ..negative(cpu.X),
  ],
  merge: true,
);

final BCS = Instruction(
  'BCS',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.C == 1)],
  type: InstructionType.branch,
  merge: true,
);

final CLV = Instruction('CLV', (write) => [(cpu) => cpu.V = 0], merge: true);

final TSX = Instruction(
  'TSX',
  (write) => [
    (cpu) =>
        cpu
          ..X = cpu.SP
          ..zero(cpu.X)
          ..negative(cpu.X),
  ],
  merge: true,
);

final CPY = Instruction(
  'CPY',
  (write) => [
    (cpu) {
      final result = cpu.Y - cpu.operand;

      cpu
        ..C = result >= 0 ? 1 : 0
        ..zero(result)
        ..negative(result);
    },
  ],
  isRead: true,
  merge: true,
);

final CMP = Instruction(
  'CMP',
  (write) => [
    (cpu) {
      final result = cpu.A - cpu.operand;

      cpu
        ..C = result >= 0 ? 1 : 0
        ..zero(result)
        ..negative(result);
    },
  ],
  isRead: true,
  merge: true,
);

final DEC = Instruction(
  'DEC',
  (write) {
    return [
      (cpu) {
        final result = (cpu.operand - 1) & 0xff;

        cpu
          ..zero(result)
          ..negative(result);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final INY = Instruction(
  'INY',
  (write) => [
    (cpu) =>
        cpu
          ..Y = (cpu.Y + 1) & 0xff
          ..zero(cpu.Y)
          ..negative(cpu.Y),
  ],
  merge: true,
);

final DEX = Instruction(
  'DEX',
  (write) => [
    (cpu) =>
        cpu
          ..X = (cpu.X - 1) & 0xff
          ..zero(cpu.X)
          ..negative(cpu.X),
  ],
  merge: true,
);

final BNE = Instruction(
  'BNE',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.Z == 0)],
  type: InstructionType.branch,
  merge: true,
);

final CLD = Instruction('CLD', (write) => [(cpu) => cpu.D = 0], merge: true);

final CPX = Instruction(
  'CPX',
  (write) => [
    (cpu) {
      final result = cpu.X - cpu.operand;

      cpu
        ..C = result >= 0 ? 1 : 0
        ..zero(result)
        ..negative(result);
    },
  ],
  isRead: true,
  merge: true,
);

final SBC = Instruction(
  'SBC',
  (write) => [
    (cpu) {
      final result = cpu.A - cpu.operand - (1 - cpu.C);
      final maskedResult = result & 0xff;

      cpu
        ..C = result >= 0 ? 1 : 0
        ..zero(maskedResult)
        ..V = ((cpu.A ^ result) & (cpu.A ^ cpu.operand) & 0x80) != 0 ? 1 : 0
        ..negative(result)
        ..A = maskedResult;
    },
  ],
  isRead: true,
  merge: true,
);

final INC = Instruction(
  'INC',
  (write) {
    return [
      (cpu) {
        final result = (cpu.operand + 1) & 0xff;

        cpu
          ..zero(result)
          ..negative(result);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final INX = Instruction(
  'INX',
  (write) => [
    (cpu) =>
        cpu
          ..X = (cpu.X + 1) & 0xff
          ..zero(cpu.X)
          ..negative(cpu.X),
  ],
  merge: true,
);

final NOP = Instruction(
  'NOP',
  (write) => [(cpu) {}],
  merge: true,
  isRead: true,
);

final BEQ = Instruction(
  'BEQ',
  (write) => [(cpu) => cpu.branch(doBranch: cpu.Z == 1)],
  type: InstructionType.branch,
  merge: true,
);

final SED = Instruction('SED', (write) => [(cpu) => cpu.D = 1], merge: true);

final LAX = Instruction(
  'LAX',
  (write) => [
    (cpu) {
      cpu
        // LDA
        ..A = cpu.operand
        // LDX
        ..X = cpu.operand
        ..zero(cpu.X)
        ..negative(cpu.X);
    },
  ],
  isRead: true,
  merge: true,
);

final SAX = Instruction(
  'SAX',
  (write) => [(cpu) => write(cpu, cpu.A & cpu.X)],
  isWrite: true,
  merge: true,
);

final DCP = Instruction(
  'DCP',
  (write) {
    return [
      (cpu) {
        // DEC
        final decResult = (cpu.operand - 1) & 0xff;

        // CMP
        final result = cpu.A - decResult;

        cpu
          ..C = result >= 0 ? 1 : 0
          ..zero(result)
          ..negative(result);

        write(cpu, decResult, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final ISC = Instruction(
  'ISC',
  (write) {
    return [
      (cpu) {
        // INC
        final incResult = (cpu.operand + 1) & 0xff;

        // SBC
        final result = cpu.A - incResult - (1 - cpu.C);
        final maskedResult = result & 0xff;

        cpu
          ..C = result >= 0 ? 1 : 0
          ..zero(maskedResult)
          ..V = ((cpu.A ^ result) & (cpu.A ^ incResult) & 0x80) != 0 ? 1 : 0
          ..negative(result)
          ..A = maskedResult;

        write(cpu, incResult, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final SLO = Instruction(
  'SLO',
  (write) {
    return [
      (cpu) {
        final aslResult = (cpu.operand << 1) & 0xff;

        cpu
          // ASL, ORA
          ..A |= aslResult
          ..C = cpu.operand.bit(7)
          ..zero(cpu.A)
          ..negative(cpu.A);

        write(cpu, aslResult, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final RLA = Instruction(
  'RLA',
  (write) {
    return [
      (cpu) {
        // ROL
        final result = ((cpu.operand << 1) | cpu.C) & 0xff;

        cpu
          // AND
          ..C = cpu.operand.bit(7)
          ..A &= result
          ..zero(cpu.A)
          ..negative(cpu.A);

        write(cpu, result, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final SRE = Instruction(
  'SRE',
  (write) {
    return [
      (cpu) {
        // LSR
        final lsrResult = cpu.operand >> 1;

        // EOR
        cpu
          ..A ^= lsrResult
          ..C = cpu.operand.bit(0)
          ..zero(cpu.A)
          ..negative(cpu.A);

        write(cpu, lsrResult, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final RRA = Instruction(
  'RRA',
  (write) {
    return [
      (cpu) {
        // ROR
        final rorResult = (cpu.operand >> 1) | (cpu.C << 7);

        cpu
          ..C = cpu.operand.bit(0)
          ..zero(rorResult)
          ..negative(rorResult);

        // ADC
        final result = cpu.A + rorResult + cpu.C;
        final maskedResult = result & 0xff;

        cpu
          ..C = result > 0xff ? 1 : 0
          ..zero(maskedResult)
          ..V = (~(cpu.A ^ rorResult) & (cpu.A ^ result)).bit(7)
          ..negative(result)
          ..A = maskedResult;

        write(cpu, rorResult, dummy: true);
      },
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final STP = Instruction('STP', (write) => [(cpu) => throw Stop()], merge: true);

final ANC = Instruction(
  'ANC',
  (write) => [
    (cpu) {
      cpu
        ..A &= cpu.operand
        ..zero(cpu.A)
        ..negative(cpu.A)
        ..C = cpu.N;
    },
  ],
  isRead: true,
  merge: true,
);

final ALR = Instruction(
  'ALR',
  (write) {
    return [
      (cpu) {
        cpu
          // AND
          ..A &= cpu.operand
          // LSR
          ..C = cpu.A.bit(0)
          ..A = cpu.A >> 1
          ..zero(cpu.A)
          ..negative(cpu.A);
      },
    ];
  },
  isRead: true,
  merge: true,
);

final ARR = Instruction(
  'ARR',
  (write) {
    return [
      (cpu) =>
          cpu
            // AND
            ..A &= cpu.operand
            // ROR
            ..A = (cpu.C << 7) | (cpu.A >> 1)
            ..zero(cpu.A)
            ..negative(cpu.A)
            ..C = cpu.A.bit(6)
            ..V = cpu.C ^ cpu.A.bit(5),
    ];
  },
  isRead: true,
  isWrite: true,
  merge: true,
);

final XAA = Instruction(
  'XAA',
  (write) => [
    (cpu) {
      cpu
        ..negative(cpu.A)
        ..zero(cpu.A)
        ..A = (cpu.A | 0xee) & cpu.X & cpu.operand;
    },
  ],
  isRead: true,
  merge: true,
);

final AHX = Instruction(
  'AHX',
  (write) => [(cpu) => write(cpu, cpu.A & cpu.X & ((cpu.address >> 8) + 1))],
  isWrite: true,
  merge: true,
);

final TAS = Instruction(
  'TAS',
  (write) => [
    (cpu) {
      cpu.SP = cpu.A & cpu.X;

      write(cpu, cpu.SP & ((cpu.address >> 8) + 1));
    },
  ],
  isWrite: true,
  merge: true,
);

final SHY = Instruction(
  'SHY',
  (write) => [
    (cpu) {
      final address = cpu.address;
      final baseAddress = cpu.address - cpu.X;

      final addressLow = address & 0xff;

      var addressHigh = address >> 8;

      if (wasPageCrossed(baseAddress, address)) {
        addressHigh &= cpu.Y;
      }

      cpu.address = (addressHigh << 8) | addressLow;

      write(cpu, cpu.Y & ((cpu.address >> 8) + 1));
    },
  ],
  isWrite: true,
  merge: true,
);

final SHX = Instruction(
  'SHX',
  (write) => [
    (cpu) {
      final address = cpu.address;
      final baseAddress = cpu.address - cpu.Y;

      final addressLow = address & 0xff;

      var addressHigh = address >> 8;

      if (wasPageCrossed(baseAddress, address)) {
        addressHigh &= cpu.X;
      }

      cpu.address = (addressHigh << 8) | addressLow;

      write(cpu, cpu.X & ((cpu.address >> 8) + 1));
    },
  ],
  isWrite: true,
  merge: true,
);

final LAS = Instruction(
  'LAS',
  (write) => [
    (cpu) {
      cpu
        ..A = cpu.SP & cpu.operand
        ..X = cpu.A
        ..SP = cpu.A
        ..zero(cpu.A)
        ..negative(cpu.A);
    },
  ],
  isRead: true,
  merge: true,
);

final AXS = Instruction(
  'AXS',
  (write) => [
    (cpu) {
      final ax = cpu.A & cpu.X;
      final result = (ax - cpu.operand) & 0xff;

      cpu
        ..C = ax >= cpu.operand ? 1 : 0
        ..X = result
        ..zero(result)
        ..negative(result);
    },
  ],
  isRead: true,
  merge: true,
);
