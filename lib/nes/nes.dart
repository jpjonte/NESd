import 'dart:io';

import 'package:nes/extension/hex_extension.dart';
import 'package:nes/nes/apu/apu.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cpu/address_mode.dart';
import 'package:nes/nes/cpu/cpu.dart';
import 'package:nes/nes/cpu/instruction.dart';
import 'package:nes/nes/cpu/operation.dart';
import 'package:nes/nes/ppu/ppu.dart';

class NES {
  NES({this.debug = false}) {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;

    if (debug) {
      File('logs/debug.log').writeAsStringSync('');
    }
  }

  final bool debug;

  Cartridge? cartridge;

  final Bus bus = Bus();
  late final CPU cpu = CPU(bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  void loadCartridge(Cartridge cartridge) {
    bus.cartridge = cartridge;

    reset();
  }

  void reset() {
    cpu.reset();
    apu.reset();
    ppu.reset();
  }

  void step() {
    _debug();

    final cycles = cpu.step();

    for (var i = 0; i < cycles * 3; i++) {
      ppu.step();
    }
  }

  void _debug() {
    if (!debug) {
      return;
    }

    final pc = cpu.PC;

    final opcode = bus.cpu.read(pc);

    _debugOp(pc, opcode);

    final op = ops[opcode];

    if (op == null) {
      return;
    }

    final operands = _getOperands(op, pc);

    _debugOpAssembly(op, operands);
    _debugOpDisassembled(pc, op, operands);
    _debugRegisters();
    _debugCycles();
  }

  void _debugOp(int pc, int opcode) {
    _writeDebug('${pc.toHex(4)}  ${opcode.toHex()} ');
  }

  List<int> _getOperands(Operation op, int pc) {
    final count = op.addressMode.operandCount;

    final operands = List.generate(
      count,
      (index) => bus.cpuRead(pc + 1 + index),
      growable: false,
    );
    return operands;
  }

  void _debugOpAssembly(Operation op, List<int> operands) {
    final formattedOperands = operands.map((o) => '${o.toHex()} ').join();
    final assembly = formattedOperands + ('   ' * (2 - operands.length));

    _writeDebug('$assembly ');
  }

  void _debugOpDisassembled(int pc, Operation op, List<int> operands) {
    final (address, _) = op.addressMode.read(cpu, pc + 1);
    final value = bus.cpuRead(address);

    final addressDebug = op.addressMode.debug(cpu, pc + 1, operands, address);

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

    _writeDebug(
      '$mark${op.instruction.name} '
      '${disassembly.padRight(28)}',
    );
  }

  void _debugRegisters() {
    _writeDebug('A:${cpu.A.toHex()} '
        'X:${cpu.X.toHex()} '
        'Y:${cpu.Y.toHex()} '
        'P:${cpu.P.toHex()} '
        'SP:${cpu.SP.toHex()} ');
  }

  void _debugCycles() {
    _writeDebug(
      'PPU:${(bus.ppu.cycle ~/ 341).toString().padLeft(3)}, '
      '${(bus.ppu.cycle % 341).toString().padLeft(3)}'
      ' CYC:${cpu.cycles}\n',
    );
  }

  void _writeDebug(String message) {
    stdout.write(message);

    File('logs/debug.log').writeAsStringSync(message, mode: FileMode.append);
  }
}
