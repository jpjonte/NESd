// instruction names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'package:nesd/exception/stop.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu.dart';

enum InstructionType { jump, branch, other }

abstract class Instruction {
  String get name;

  void execute(CPU cpu);

  bool get isWrite => false;

  InstructionType get type => InstructionType.other;

  int read(CPU cpu) => cpu.operation.addressMode.read(cpu);

  void write(CPU cpu, int result) =>
      cpu.operation.addressMode.write(cpu, result);
}

class BRK extends Instruction {
  @override
  String get name => 'BRK';

  @override
  void execute(CPU cpu) {
    cpu
      ..callStack.add(cpu.PC + 1)
      ..pushStack16(cpu.PC + 1)
      ..pushStack(cpu.P.setBit(4, 1).setBit(5, 1));

    if (cpu.doNmi) {
      cpu
        ..doNmi = false
        ..address = nmiVector;
    } else {
      cpu.address = irqVector;
    }

    cpu
      ..I = 1
      ..PC = cpu.read16(cpu.address);
  }
}

class ORA extends Instruction {
  @override
  String get name => 'ORA';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A |= operand
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class ASL extends Instruction {
  @override
  String get name => 'ASL';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = (operand << 1) & 0xff;

    cpu
      ..C = operand.bit(7)
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class PHP extends Instruction {
  @override
  String get name => 'PHP';

  @override
  void execute(CPU cpu) => cpu.pushStack(cpu.P.setBit(4, 1));
}

class BPL extends Instruction {
  @override
  String get name => 'BPL';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.N == 0);

  @override
  InstructionType get type => InstructionType.branch;
}

class CLC extends Instruction {
  @override
  String get name => 'CLC';

  @override
  void execute(CPU cpu) => cpu.C = 0;
}

class JSR extends Instruction {
  @override
  String get name => 'JSR';

  @override
  void execute(CPU cpu) {
    cpu
      ..read(cpu.PC) // dummy read
      ..pushStack16(cpu.PC - 1)
      ..PC = cpu.address;
  }

  @override
  InstructionType get type => InstructionType.jump;
}

class AND extends Instruction {
  @override
  String get name => 'AND';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A &= operand
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class BIT extends Instruction {
  @override
  String get name => 'BIT';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.A & operand;

    cpu
      ..zero(result)
      ..V = operand.bit(6)
      ..negative(operand);
  }
}

class ROL extends Instruction {
  @override
  String get name => 'ROL';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = ((operand << 1) | cpu.C) & 0xff;

    cpu
      ..C = operand.bit(7)
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class PLP extends Instruction {
  @override
  String get name => 'PLP';

  @override
  void execute(CPU cpu) {
    cpu.read(cpu.PC); // dummy read

    final result = cpu.popStack();

    cpu
      ..C = result.bit(0)
      ..Z = result.bit(1)
      ..I = result.bit(2)
      ..D = result.bit(3)
      ..V = result.bit(6)
      ..negative(result);
  }
}

class BMI extends Instruction {
  @override
  String get name => 'BMI';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.N == 1);

  @override
  InstructionType get type => InstructionType.branch;
}

class SEC extends Instruction {
  @override
  String get name => 'SEC';

  @override
  void execute(CPU cpu) => cpu.C = 1;
}

class RTI extends Instruction {
  @override
  String get name => 'RTI';

  @override
  void execute(CPU cpu) {
    cpu
      ..read(cpu.PC) // dummy read
      ..P = cpu.popStack().setBit(5, 1)
      ..PC = cpu.popStack16();
  }
}

class EOR extends Instruction {
  @override
  String get name => 'EOR';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A ^= operand
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class LSR extends Instruction {
  @override
  String get name => 'LSR';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = operand >> 1;

    cpu
      ..C = operand.bit(0)
      ..zero(result)
      ..N = 0;

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class PHA extends Instruction {
  @override
  String get name => 'PHA';

  @override
  void execute(CPU cpu) => cpu.pushStack(cpu.A);
}

class JMP extends Instruction {
  @override
  String get name => 'JMP';

  @override
  void execute(CPU cpu) => cpu.PC = cpu.address;

  @override
  InstructionType get type => InstructionType.jump;
}

class BVC extends Instruction {
  @override
  String get name => 'BVC';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.V == 0);

  @override
  InstructionType get type => InstructionType.branch;
}

class CLI extends Instruction {
  @override
  String get name => 'CLI';

  @override
  void execute(CPU cpu) => cpu.I = 0;
}

class RTS extends Instruction {
  @override
  String get name => 'RTS';

  @override
  void execute(CPU cpu) {
    final target = cpu.popStack16();

    cpu
      ..read(cpu.PC) // dummy read
      ..read(cpu.PC) // dummy read
      ..PC = target + 1;
  }
}

class ADC extends Instruction {
  @override
  String get name => 'ADC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.A + operand + cpu.C;
    final maskedResult = result & 0xff;

    cpu
      ..C = result > 0xff ? 1 : 0
      ..zero(maskedResult)
      ..V = (~(cpu.A ^ operand) & (cpu.A ^ result) & 0x80) != 0 ? 1 : 0
      ..negative(result)
      ..A = maskedResult;
  }
}

class ROR extends Instruction {
  @override
  String get name => 'ROR';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = (cpu.C << 7) | (operand >> 1);

    cpu
      ..C = operand.bit(0)
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class PLA extends Instruction {
  @override
  String get name => 'PLA';

  @override
  void execute(CPU cpu) {
    cpu.read(cpu.PC); // dummy read

    final result = cpu.popStack();

    cpu
      ..A = result
      ..zero(result)
      ..negative(result);
  }
}

class BVS extends Instruction {
  @override
  String get name => 'BVS';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.V == 1);

  @override
  InstructionType get type => InstructionType.branch;
}

class SEI extends Instruction {
  @override
  String get name => 'SEI';

  @override
  void execute(CPU cpu) => cpu.I = 1;
}

class STA extends Instruction {
  @override
  String get name => 'STA';

  @override
  void execute(CPU cpu) => write(cpu, cpu.A);

  @override
  bool get isWrite => true;
}

class STY extends Instruction {
  @override
  String get name => 'STY';

  @override
  void execute(CPU cpu) => write(cpu, cpu.Y);

  @override
  bool get isWrite => true;
}

class STX extends Instruction {
  @override
  String get name => 'STX';

  @override
  void execute(CPU cpu) => write(cpu, cpu.X);

  @override
  bool get isWrite => true;
}

class DEY extends Instruction {
  @override
  String get name => 'DEY';

  @override
  void execute(CPU cpu) =>
      cpu
        ..Y = (cpu.Y - 1) & 0xff
        ..zero(cpu.Y)
        ..negative(cpu.Y);
}

class TXA extends Instruction {
  @override
  String get name => 'TXA';

  @override
  void execute(CPU cpu) =>
      cpu
        ..A = cpu.X
        ..zero(cpu.A)
        ..negative(cpu.A);
}

class BCC extends Instruction {
  @override
  String get name => 'BCC';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.C == 0);

  @override
  InstructionType get type => InstructionType.branch;
}

class TYA extends Instruction {
  @override
  String get name => 'TYA';

  @override
  void execute(CPU cpu) =>
      cpu
        ..A = cpu.Y
        ..zero(cpu.A)
        ..negative(cpu.A);
}

class TXS extends Instruction {
  @override
  String get name => 'TXS';

  @override
  void execute(CPU cpu) => cpu.SP = cpu.X;
}

class LDY extends Instruction {
  @override
  String get name => 'LDY';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..Y = operand
      ..zero(cpu.Y)
      ..negative(cpu.Y);
  }
}

class LDA extends Instruction {
  @override
  String get name => 'LDA';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A = operand
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class LDX extends Instruction {
  @override
  String get name => 'LDX';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..X = operand
      ..zero(cpu.X)
      ..negative(cpu.X);
  }
}

class TAY extends Instruction {
  @override
  String get name => 'TAY';

  @override
  void execute(CPU cpu) =>
      cpu
        ..Y = cpu.A
        ..zero(cpu.Y)
        ..negative(cpu.Y);
}

class TAX extends Instruction {
  @override
  String get name => 'TAX';

  @override
  void execute(CPU cpu) =>
      cpu
        ..X = cpu.A
        ..zero(cpu.X)
        ..negative(cpu.X);
}

class BCS extends Instruction {
  @override
  String get name => 'BCS';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.C == 1);

  @override
  InstructionType get type => InstructionType.branch;
}

class CLV extends Instruction {
  @override
  String get name => 'CLV';

  @override
  void execute(CPU cpu) => cpu.V = 0;
}

class TSX extends Instruction {
  @override
  String get name => 'TSX';

  @override
  void execute(CPU cpu) =>
      cpu
        ..X = cpu.SP
        ..zero(cpu.X)
        ..negative(cpu.X);
}

class CPY extends Instruction {
  @override
  String get name => 'CPY';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.Y - operand;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(result)
      ..negative(result);
  }
}

class CMP extends Instruction {
  @override
  String get name => 'CMP';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.A - operand;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(result)
      ..negative(result);
  }
}

class DEC extends Instruction {
  @override
  String get name => 'DEC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = (operand - 1) & 0xff;

    cpu
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class INY extends Instruction {
  @override
  String get name => 'INY';

  @override
  void execute(CPU cpu) =>
      cpu
        ..Y = (cpu.Y + 1) & 0xff
        ..zero(cpu.Y)
        ..negative(cpu.Y);
}

class DEX extends Instruction {
  @override
  String get name => 'DEX';

  @override
  void execute(CPU cpu) =>
      cpu
        ..X = (cpu.X - 1) & 0xff
        ..zero(cpu.X)
        ..negative(cpu.X);
}

class BNE extends Instruction {
  @override
  String get name => 'BNE';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.Z == 0);

  @override
  InstructionType get type => InstructionType.branch;
}

class CLD extends Instruction {
  @override
  String get name => 'CLD';

  @override
  void execute(CPU cpu) => cpu.D = 0;
}

class CPX extends Instruction {
  @override
  String get name => 'CPX';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.X - operand;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(result)
      ..negative(result);
  }
}

class SBC extends Instruction {
  @override
  String get name => 'SBC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = cpu.A - operand - (1 - cpu.C);
    final maskedResult = result & 0xff;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(maskedResult)
      ..V = ((cpu.A ^ result) & (cpu.A ^ operand) & 0x80) != 0 ? 1 : 0
      ..negative(result)
      ..A = maskedResult;
  }
}

class INC extends Instruction {
  @override
  String get name => 'INC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final result = (operand + 1) & 0xff;

    cpu
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class INX extends Instruction {
  @override
  String get name => 'INX';

  @override
  void execute(CPU cpu) =>
      cpu
        ..X = (cpu.X + 1) & 0xff
        ..zero(cpu.X)
        ..negative(cpu.X);
}

class NOP extends Instruction {
  @override
  String get name => 'NOP';

  @override
  void execute(CPU cpu) => read(cpu); // dummy read
}

class BEQ extends Instruction {
  @override
  String get name => 'BEQ';

  @override
  void execute(CPU cpu) => cpu.branch(doBranch: cpu.Z == 1);

  @override
  InstructionType get type => InstructionType.branch;
}

class SED extends Instruction {
  @override
  String get name => 'SED';

  @override
  void execute(CPU cpu) => cpu.D = 1;
}

class LAX extends Instruction {
  @override
  String get name => 'LAX';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      // LDA
      ..A = operand
      // LDX
      ..X = operand
      ..zero(cpu.X)
      ..negative(cpu.X);
  }
}

class SAX extends Instruction {
  @override
  String get name => 'SAX';

  @override
  void execute(CPU cpu) => write(cpu, cpu.A & cpu.X);

  @override
  bool get isWrite => true;
}

class DCP extends Instruction {
  @override
  String get name => 'DCP';

  @override
  void execute(CPU cpu) {
    // DEC
    final operand = read(cpu);
    final decResult = (operand - 1) & 0xff;

    // CMP
    final result = cpu.A - decResult;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(result)
      ..negative(result);

    write(cpu, operand); // dummy write
    write(cpu, decResult);
  }

  @override
  bool get isWrite => true;
}

class ISC extends Instruction {
  @override
  String get name => 'ISC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    // INC
    final incResult = (operand + 1) & 0xff;

    // SBC
    final result = cpu.A - incResult - (1 - cpu.C);
    final maskedResult = result & 0xff;

    cpu
      ..C = result >= 0 ? 1 : 0
      ..zero(maskedResult)
      ..V = ((cpu.A ^ result) & (cpu.A ^ incResult) & 0x80) != 0 ? 1 : 0
      ..negative(result)
      ..A = maskedResult;

    write(cpu, operand); // dummy write
    write(cpu, incResult);
  }

  @override
  bool get isWrite => true;
}

class SLO extends Instruction {
  @override
  String get name => 'SLO';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);
    final aslResult = (operand << 1) & 0xff;

    cpu
      // ASL, ORA
      ..A |= aslResult
      ..C = operand.bit(7)
      ..zero(cpu.A)
      ..negative(cpu.A);

    write(cpu, operand); // dummy write
    write(cpu, aslResult);
  }

  @override
  bool get isWrite => true;
}

class RLA extends Instruction {
  @override
  String get name => 'RLA';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    // ROL
    final result = ((operand << 1) | cpu.C) & 0xff;

    cpu
      // AND
      ..C = operand.bit(7)
      ..A &= result
      ..zero(cpu.A)
      ..negative(cpu.A);

    write(cpu, operand); // dummy write
    write(cpu, result);
  }

  @override
  bool get isWrite => true;
}

class SRE extends Instruction {
  @override
  String get name => 'SRE';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    // LSR
    final lsrResult = operand >> 1;

    // EOR
    cpu
      ..A ^= lsrResult
      ..C = operand.bit(0)
      ..zero(cpu.A)
      ..negative(cpu.A);

    write(cpu, operand); // dummy write
    write(cpu, lsrResult);
  }

  @override
  bool get isWrite => true;
}

class RRA extends Instruction {
  @override
  String get name => 'RRA';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    // ROR
    final rorResult = (operand >> 1) | (cpu.C << 7);

    cpu
      ..C = operand.bit(0)
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

    write(cpu, operand); // dummy write
    write(cpu, rorResult);
  }

  @override
  bool get isWrite => true;
}

class STP extends Instruction {
  @override
  String get name => 'STP';

  @override
  void execute(CPU cpu) => throw Stop();
}

class ANC extends Instruction {
  @override
  String get name => 'ANC';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A &= operand
      ..zero(cpu.A)
      ..negative(cpu.A)
      ..C = cpu.N;
  }
}

class ALR extends Instruction {
  @override
  String get name => 'ALR';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      // AND
      ..A &= operand
      // LSR
      ..C = cpu.A.bit(0)
      ..A = cpu.A >> 1
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class ARR extends Instruction {
  @override
  String get name => 'ARR';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      // AND
      ..A &= operand
      // ROR
      ..A = (cpu.C << 7) | (cpu.A >> 1)
      ..zero(cpu.A)
      ..negative(cpu.A)
      ..C = cpu.A.bit(6)
      ..V = cpu.C ^ cpu.A.bit(5);
  }

  @override
  bool get isWrite => true;
}

class XAA extends Instruction {
  @override
  String get name => 'XAA';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..negative(cpu.A)
      ..zero(cpu.A)
      ..A = (cpu.A | 0xee) & cpu.X & operand;
  }
}

class AHX extends Instruction {
  @override
  String get name => 'AHX';

  @override
  void execute(CPU cpu) => write(cpu, cpu.A & cpu.X & ((cpu.address >> 8) + 1));

  @override
  bool get isWrite => true;
}

class TAS extends Instruction {
  @override
  String get name => 'TAS';

  @override
  void execute(CPU cpu) {
    cpu.SP = cpu.A & cpu.X;

    write(cpu, cpu.SP & ((cpu.address >> 8) + 1));
  }

  @override
  bool get isWrite => true;
}

class SHY extends Instruction {
  @override
  String get name => 'SHY';

  @override
  void execute(CPU cpu) {
    final address = cpu.address;
    final baseAddress = cpu.address - cpu.X;

    final addressLow = address & 0xff;

    var addressHigh = address >> 8;

    if (wasPageCrossed(baseAddress, address)) {
      addressHigh &= cpu.Y;
    }

    cpu.address = (addressHigh << 8) | addressLow;

    write(cpu, cpu.Y & ((cpu.address >> 8) + 1));
  }

  @override
  bool get isWrite => true;
}

class SHX extends Instruction {
  @override
  String get name => 'SHX';

  @override
  void execute(CPU cpu) {
    final address = cpu.address;
    final baseAddress = cpu.address - cpu.Y;

    final addressLow = address & 0xff;

    var addressHigh = address >> 8;

    if (wasPageCrossed(baseAddress, address)) {
      addressHigh &= cpu.X;
    }

    cpu.address = (addressHigh << 8) | addressLow;

    write(cpu, cpu.X & ((cpu.address >> 8) + 1));
  }

  @override
  bool get isWrite => true;
}

class LAS extends Instruction {
  @override
  String get name => 'LAS';

  @override
  void execute(CPU cpu) {
    final operand = read(cpu);

    cpu
      ..A = cpu.SP & operand
      ..X = cpu.A
      ..SP = cpu.A
      ..zero(cpu.A)
      ..negative(cpu.A);
  }
}

class AXS extends Instruction {
  @override
  String get name => 'AXS';

  @override
  void execute(CPU cpu) {
    final ax = cpu.A & cpu.X;
    final operand = read(cpu);
    final result = (ax - operand) & 0xff;

    cpu
      ..C = ax >= operand ? 1 : 0
      ..X = result
      ..zero(result)
      ..negative(result);
  }
}
