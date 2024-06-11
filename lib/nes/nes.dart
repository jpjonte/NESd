import 'dart:io';
import 'dart:typed_data';

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
import 'package:nes/util/wait.dart';

sealed class NesEvent {}

class FrameNesEvent extends NesEvent {
  FrameNesEvent({
    required this.frameBuffer,
    required this.samples,
    required this.frameTime,
  });

  final FrameBuffer frameBuffer;
  final Float32List samples;
  final Duration frameTime;
}

sealed class NesCommand {}

class NesResetCommand extends NesCommand {}

class NesPauseCommand extends NesCommand {}

class NesUnpauseCommand extends NesCommand {}

class NesTogglePauseCommand extends NesCommand {}

class NesSuspendCommand extends NesCommand {}

class NesResumeCommand extends NesCommand {}

class NesStopCommand extends NesCommand {}

class NesStepCommand extends NesCommand {}

class NesRunUntilFrameCommand extends NesCommand {}

class NesButtonDownCommand extends NesCommand {
  NesButtonDownCommand(this.controller, this.button);

  final int controller;
  final NesButton button;
}

class NesButtonUpCommand extends NesCommand {
  NesButtonUpCommand(this.controller, this.button);

  final int controller;
  final NesButton button;
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

  bool on = false;
  bool running = false;
  bool paused = false;
  bool stopAfterNextFrame = false;

  late DateTime _frameStart;

  final Bus bus = Bus();
  late final CPU cpu = CPU(bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  int cycles = 0;

  var _sleepBudget = Duration.zero;

  void loadCartridge(Cartridge cartridge) {
    bus.cartridge = cartridge;

    reset();
  }

  void reset() {
    cycles = 0;

    _frameStart = DateTime.now();
    _sleepBudget = Duration.zero;

    bus.cartridge?.reset();

    cpu.reset();
    apu.reset();
    ppu.reset();
  }

  Stream<NesEvent> run() async* {
    reset();

    on = true;
    running = true;
    paused = false;

    _frameStart = DateTime.now();

    while (on) {
      if (!running) {
        await wait(const Duration(milliseconds: 10));

        continue;
      }

      final vblankBefore = ppu.PPUSTATUS_V;

      step();

      if (vblankBefore == 0 && ppu.PPUSTATUS_V == 1) {
        final frameTime = DateTime.now().difference(_frameStart);

        yield FrameNesEvent(
          frameBuffer: ppu.frameBuffer,
          samples: apu.sampleBuffer.sublist(0, apu.sampleIndex),
          frameTime: frameTime,
        );

        final sleepTime = _calculateSleepTime(frameTime, apu.sampleIndex);

        _sleepBudget += sleepTime;

        apu.sampleIndex = 0;

        if (stopAfterNextFrame) {
          running = false;
          stopAfterNextFrame = false;
          paused = true;
        }

        _frameStart = DateTime.now();

        await wait(_sleepBudget);
      }
    }
  }

  Duration _calculateSleepTime(Duration elapsedTime, int samples) {
    final targetAudioTime = 1000000 * samples / apuSampleRate;
    final time = targetAudioTime - elapsedTime.inMicroseconds;

    return Duration(microseconds: time.floor());
  }

  void executeCommand(NesCommand command) {
    switch (command) {
      case final NesResetCommand _:
        reset();
        running = true;
        paused = false;
        _frameStart = DateTime.now();
      case final NesPauseCommand _:
        paused = true;
        running = false;
      case NesTogglePauseCommand():
        paused = !paused;
        running = !running;
        _frameStart = DateTime.now();
      case NesUnpauseCommand():
        paused = false;
        running = true;
        _frameStart = DateTime.now();
      case NesSuspendCommand _:
        running = false;
      case NesResumeCommand _:
        if (!paused) {
          running = true;
          _frameStart = DateTime.now();
        }
      case NesStopCommand _:
        on = false;
      case NesStepCommand _:
        if (!running) {
          step();
        }
      case NesRunUntilFrameCommand _:
        running = true;
        stopAfterNextFrame = true;
      case final NesButtonDownCommand command:
        bus.buttonDown(command.controller, command.button);
      case final NesButtonUpCommand command:
        bus.buttonUp(command.controller, command.button);
    }
  }

  void step() {
    _debug();

    cycles++;

    while (cpu.cycles < cycles / 12) {
      cpu.step();
    }

    while (ppu.cycles < cycles / 4) {
      ppu.step();
    }

    while (apu.cycles < cycles / 12) {
      apu.step();
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
