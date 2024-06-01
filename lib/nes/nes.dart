import 'dart:io';

import 'package:nes/extension/hex_extension.dart';
import 'package:nes/nes/apu/apu.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cpu/address_mode.dart';
import 'package:nes/nes/cpu/cpu.dart';
import 'package:nes/nes/cpu/instruction.dart';
import 'package:nes/nes/cpu/operation.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/nes/ppu/ppu.dart';

enum NesCommand {
  reset,
  pause,
  resume,
  stop,
  step,
  runUntilFrame,
}

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

  bool on = false;
  bool running = false;

  final Bus bus = Bus();
  late final CPU cpu = CPU(bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  void loadCartridge(Cartridge cartridge) {
    bus.cartridge = cartridge;

    reset();
  }

  void reset() {
    running = false;
    on = false;

    cpu.reset();
    apu.reset();
    ppu.reset();
  }

  Stream<FrameBuffer> run(Stream<NesCommand> commandStream) async* {
    commandStream.listen(_executeCommand);

    on = true;
    running = true;

    while (on) {
      if (!running) {
        return;
      }

      final vblankBefore = ppu.PPUSTATUS_V;

      step();

      if (vblankBefore == 0 && ppu.PPUSTATUS_V == 1) {
        yield ppu.frameBuffer;
      }
    }
  }

  void pause() {
    running = false;
  }

  void resume() {
    running = true;
  }

  void stop() {
    on = false;
  }

  void _executeCommand(NesCommand command) {
    switch (command) {
      case NesCommand.reset:
        reset();
      case NesCommand.pause:
        pause();
      case NesCommand.resume:
        resume();
      case NesCommand.stop:
        stop();
      case NesCommand.step:
        if (!running) {
          step();
        }
      case NesCommand.runUntilFrame:
        if (!running) {
          while (ppu.PPUSTATUS_V == 0) {
            step();
          }
        }
    }
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
      'PPU:${bus.ppu.scanline.toString().padLeft(3)}, '
      '${bus.ppu.cycle.toString().padLeft(3)}'
      ' CYC:${cpu.cycles}\n',
    );
  }

  void _writeDebug(String message) {
    stdout.write(message);

    File('logs/debug.log').writeAsStringSync(message, mode: FileMode.append);
  }
}
