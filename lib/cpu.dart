// ignore_for_file: non_constant_identifier_names
// ignore_for_file: parameter_assignments

import 'dart:io';
import 'dart:typed_data';

import 'package:nes/address_mode.dart';
import 'package:nes/apu.dart';
import 'package:nes/cartridge.dart';
import 'package:nes/hex_extension.dart';
import 'package:nes/instruction.dart';
import 'package:nes/invalid_opcode.dart';
import 'package:nes/operation.dart';
import 'package:nes/ppu.dart';

class CPU {
  CPU() {
    debugLog = 'debug.log';
  }

  late final PPU ppu;
  late final APU apu;
  late final Cartridge cartridge;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  int joy1 = 0;
  int joy2 = 0;

  bool irq = false;
  bool nmi = false;

  Uint8List ram = Uint8List(0x0800);

  int get C => P & 0x01;
  int get Z => (P >> 1) & 0x01;
  int get I => (P >> 2) & 0x01;
  int get D => (P >> 3) & 0x01;
  int get B => (P >> 4) & 0x01;
  int get V => (P >> 6) & 0x01;
  int get N => (P >> 7) & 0x01;

  set C(int value) => P = (P & 0xfe) | (value & 0x01);
  set Z(int value) => P = (P & 0xfd) | ((value & 0x01) << 1);
  set I(int value) => P = (P & 0xfb) | ((value & 0x01) << 2);
  set D(int value) => P = (P & 0xf7) | ((value & 0x01) << 3);
  set B(int value) => P = (P & 0xef) | ((value & 0x01) << 4);
  set V(int value) => P = (P & 0xbf) | ((value & 0x01) << 6);
  set N(int value) => P = (P & 0x7f) | ((value & 0x01) << 7);

  int cycles = 0;

  bool debug = false;

  late final String debugLog;

  int read(int address) {
    if (address == addressA) {
      return A;
    }

    if (address < 0x2000) {
      return ram[address % 0x0800];
    }

    if (address < 0x4000) {
      return ppu.read(0x2000 + address % 8);
    }

    if (address < 0x4015) {
      return 0;
    }

    if (address == 0x4015) {
      return apu.status;
    }

    if (address == 0x4016) {
      // TODO bud-27.05.24 controller 1
      return 0;
    }

    if (address == 0x4017) {
      // TODO bud-27.05.24 controller 2
      return 0;
    }

    if (address < 0x4020) {
      return 0;
    }

    return cartridge.read(address);
  }

  int read16(int address, {bool wrap = false}) {
    final low = read(address);

    final highAddress =
        wrap ? (address & 0xff00 | ((address + 1) & 0xff)) : address + 1;

    final high = read(highAddress);

    return low | (high << 8);
  }

  void write(int address, int value) {
    if (address == addressA) {
      A = value;

      return;
    }

    address &= 0xffff;
    value &= 0xff;

    if (address < 0x2000) {
      ram[address % 0x800] = value;

      return;
    }

    if (address < 0x4000) {
      ppu.write(address, value);

      return;
    }

    if (address < 0x4015) {
      return;
    }

    if (address == 0x4015) {
      apu.write(address, value);

      return;
    }

    if (address == 0x4016) {
      // TODO bud-27.05.24

      return;
    }

    if (address == 0x4017) {
      // TODO bud-27.05.24
      return;
    }

    if (address < 0x4020) {
      return;
    }

    cartridge.write(address, value);

    return;
  }

  void pushStack(int value) => write(0x100 + SP--, value & 0xff);

  void pushStack16(int value) {
    pushStack(value >> 8);
    pushStack(value & 0xff);
  }

  int popStack() => read(0x100 + ++SP);

  int popStack16() {
    final low = popStack();
    final high = popStack();

    return low | (high << 8);
  }

  void reset() {
    SP = 0xfd;
    PC = read(0xfffc) | (read(0xfffd) << 8);
    P = 0x24;
    // TODO bud-28.05.24 check if this makes sense
    cycles = 7;
  }

  int step() {
    handleInterrupts();

    final opcode = read(PC);

    final op = ops[opcode];

    if (op == null) {
      throw InvalidOpcode(PC, opcode);
    }

    debugPc(opcode);

    PC++;

    final count = op.addressMode.operandCount;

    final operands = List.generate(count, (index) => read(PC + index));

    debugOpAssembly(op, operands);

    final (address, pageCrossed) = op.addressMode.read(this);

    debugOpDisassembled(op, operands, address);
    debugRegisters();
    debugCycles();

    final start = PC;

    op.instruction.execute(this, address);

    var additionalCycles = 0;

    if (op.instruction.type == InstructionType.branch && start != PC) {
      additionalCycles = calculateBranchCycles(start, PC);
    }

    if (op.pageCrossAddsCycle && pageCrossed) {
      additionalCycles++;
    }

    final executedCycles = op.cycles + additionalCycles;

    cycles += executedCycles;

    return executedCycles;
  }

  void handleInterrupts() {
    // TODO bud-28.05.24 /NMI is an edge-sensitive interrupt
    // TODO bud-28.05.24 make sure that NMI is only triggered
    // TODO bud-28.05.24 when changing from false to true
    if (nmi) {
      nmi = false;

      handleIrq(0xfffa);
    }

    if (irq && I == 0) {
      irq = false;

      handleIrq(0xfffe);
    }
  }

  void handleIrq(int address) {
    irq = false;

    pushStack16(PC);
    PHP.execute(this, 0);

    I = 1;
    PC = read16(address);
  }

  int calculateBranchCycles(int from, int to) {
    return pageCrossed(from, to) ? 2 : 1;
  }

  void debugPc(int opcode) {
    writeDebug('${PC.toHex(4)}  ${opcode.toHex()} ');
  }

  void debugOpAssembly(Operation op, List<int> operands) {
    final formattedOperands = operands.map((o) => '${o.toHex()} ').join();
    final assembly = formattedOperands + ('   ' * (2 - operands.length));

    writeDebug('$assembly ');
  }

  void debugOpDisassembled(
    Operation op,
    List<int> operands,
    int address,
  ) {
    final value = read(address);

    final addressDebug = op.addressMode.debug(this, operands, address);

    var operandDebug = '';

    if (operands.isNotEmpty &&
        op.addressMode != immediate &&
        ![
          InstructionType.jump,
          InstructionType.branch,
        ].contains(op.instruction.type)) {
      operandDebug = ' = ${value.toHex()}';
    }

    final disassembly = addressDebug + operandDebug;

    final mark = op.unofficial ? '*' : ' ';

    writeDebug(
      '$mark${op.instruction.name} '
      '${disassembly.padRight(28)}',
    );
  }

  void debugRegisters() {
    writeDebug('A:${A.toHex()} '
        'X:${X.toHex()} '
        'Y:${Y.toHex()} '
        'P:${P.toHex()} '
        'SP:${SP.toHex()} ');
  }

  void debugCycles() {
    writeDebug(
      'PPU:${(ppu.cycles ~/ 341).toString().padLeft(3)}, '
      '${(ppu.cycles % 341).toString().padLeft(3)}'
      ' CYC:$cycles\n',
    );
  }

  void writeDebug(String message) {
    if (!debug) {
      return;
    }

    stdout.write(message);

    File('logs/$debugLog').writeAsStringSync(message, mode: FileMode.append);
  }
}
