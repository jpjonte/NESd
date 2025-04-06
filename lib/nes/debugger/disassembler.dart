import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disassembler.g.dart';

typedef Disassembly = List<DisassemblyLine>;

@riverpod
DisassemblerInterface disassembler(Ref ref) {
  final nes = ref.watch(nesStateProvider);

  if (nes == null) {
    return DummyDisassembler();
  }

  return Disassembler(eventBus: ref.watch(eventBusProvider), cpu: nes.cpu);
}

class DisassemblerSearchNode {
  const DisassemblerSearchNode(
    this.pc, {
    this.entrypoint = false,
    this.depth = 0,
  });

  final int pc;
  final bool entrypoint;
  final int depth;
}

abstract class DisassemblerInterface {
  Disassembly update();
  DisassemblyLine? disassembleLine(
    int address, {
    bool isEntrypoint = false,
    CPUState? state,
    int? readAddress,
    int? value,
  });
  Map<int, DisassemblyLine> get lines;
}

class Disassembler implements DisassemblerInterface {
  Disassembler({required this.eventBus, required this.cpu}) {
    final bus =
        Bus(cpu.bus.cartridge)
          ..ppu = cpu.bus.ppu
          ..apu = cpu.bus.apu;

    debugCpu = DebugCPU(bus: bus)..state = cpu.state;

    bus.cpu = debugCpu;

    _search([
      DisassemblerSearchNode(debugCpu.read16(resetVector), entrypoint: true),
      DisassemblerSearchNode(debugCpu.read16(nmiVector), entrypoint: true),
      DisassemblerSearchNode(debugCpu.read16(irqVector), entrypoint: true),
    ]);
  }

  static const depthLimit = 500;

  final EventBus eventBus;
  final CPU cpu;
  late final DebugCPU debugCpu;

  @override
  final Map<int, DisassemblyLine> lines = {};

  @override
  Disassembly update() {
    debugCpu.state = cpu.state;

    _search([DisassemblerSearchNode(cpu.PC)]);

    return lines.values.toList()
      ..sort((a, b) => a.address.compareTo(b.address));
  }

  @override
  DisassemblyLine? disassembleLine(
    int address, {
    bool isEntrypoint = false,
    CPUState? state,
    int? readAddress,
    int? value,
  }) {
    if (state != null) {
      debugCpu.state = state;
    }

    final opcode = debugCpu.read(address);

    final op = ops[opcode];

    if (op == null) {
      return null;
    }

    final operandCount = op.addressMode.operandCount;

    final operands = List.generate(
      operandCount,
      (index) => debugCpu.read(address + 1 + index),
      growable: false,
    );

    final readAddress = _getReadAddress(address);

    if (readAddress == null) {
      return null;
    }

    final value = debugCpu.read(readAddress);

    final disassembly = _disassemble(op, operands, readAddress, value);

    final line = DisassemblyLine(
      address: address,
      opcode: opcode,
      operation: op,
      operands: operands,
      disassembly: disassembly,
      readAddress: readAddress,
      sectionStart: isEntrypoint || lines[address]?.sectionStart == true,
      sectionEnd:
          op.instruction is RTS ||
          op.instruction is RTI ||
          op.instruction is JMP ||
          lines[address]?.sectionEnd == true,
    );

    lines[address] = line;

    for (var i = 1; i <= operandCount; i++) {
      final next = address + i;

      if (lines.containsKey(next)) {
        lines.remove(next);
      }
    }

    return line;
  }

  int? _getReadAddress(int address) {
    final previousPc = debugCpu.PC;

    debugCpu.PC = address;

    try {
      debugCpu.step();
    } on NesdException {
      return null;
    } finally {
      debugCpu.PC = previousPc;
    }

    return debugCpu.address;
  }

  String _disassemble(
    Operation op,
    List<int> operands,
    int readAddress,
    int value,
  ) {
    return switch (op.addressMode) {
      Implicit() => '',
      Accumulator() => 'A',
      Immediate() => '#\$${operands[0].toHex()}',
      ZeroPage() => '\$${operands[0].toHex()}',
      ZeroPageX() => '\$${operands[0].toHex()},X',
      ZeroPageY() => '\$${operands[0].toHex()},Y',
      Relative() || Absolute() => '\$${readAddress.toHex(width: 4)}',
      AbsoluteX() =>
        '\$${((readAddress - debugCpu.X) & 0xffff).toHex(width: 4)},X',
      AbsoluteY() =>
        '\$${((readAddress - debugCpu.Y) & 0xffff).toHex(width: 4)},Y',
      Indirect() => '(\$${operands[1].toHex()}${operands[0].toHex()})',
      IndexedIndirect() => '(\$${operands[0].toHex()},X)',
      IndirectIndexed() => '(\$${operands[0].toHex()}),Y',
    };
  }

  void _search(List<DisassemblerSearchNode> queue) {
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      final pc = current.pc;

      final line = disassembleLine(pc, isEntrypoint: current.entrypoint);

      if (line == null) {
        continue;
      }

      final op = line.operation;
      final operandCount = line.operation.addressMode.operandCount;

      final children = <DisassemblerSearchNode>[];

      final next = pc + 1 + operandCount;

      if (op.instruction is! JMP &&
          op.instruction is! RTS &&
          op.instruction is! RTI) {
        children.add(DisassemblerSearchNode(next, depth: current.depth + 1));
      }

      if (op.instruction.type == InstructionType.branch ||
          op.instruction.type == InstructionType.jump) {
        children.add(
          DisassemblerSearchNode(
            line.readAddress,
            entrypoint:
                op.instruction is JSR ||
                op.instruction is BRK ||
                op.instruction is JMP,
            depth: current.depth + 1,
          ),
        );
      }

      for (final child in children) {
        if (child.depth < depthLimit &&
            !visited.contains(child.pc) &&
            child.pc >= 0x0000 &&
            child.pc <= 0xffff) {
          visited.add(child.pc);
          queue.add(child);
        }
      }
    }
  }
}

class DummyDisassembler implements DisassemblerInterface {
  @override
  Disassembly update() {
    return [];
  }

  @override
  DisassemblyLine? disassembleLine(
    int address, {
    bool isEntrypoint = false,
    CPUState? state,
    int? readAddress,
    int? value,
  }) {
    throw UnimplementedError();
  }

  @override
  Map<int, DisassemblyLine> get lines => throw UnimplementedError();
}

class DisassemblyLine {
  const DisassemblyLine({
    required this.address,
    required this.opcode,
    required this.operation,
    required this.operands,
    required this.disassembly,
    required this.readAddress,
    required this.sectionStart,
    required this.sectionEnd,
  });

  final int address;
  final int opcode;
  final Operation operation;
  final List<int> operands;
  final String disassembly;
  final int readAddress;
  final bool sectionStart;
  final bool sectionEnd;

  bool get isRead => switch (operation.addressMode) {
    Implicit() || Accumulator() || Immediate() || Relative() => false,
    ZeroPage() ||
    ZeroPageX() ||
    ZeroPageY() ||
    AbsoluteX() ||
    AbsoluteY() ||
    Indirect() ||
    IndexedIndirect() ||
    IndirectIndexed() => true,
    Absolute() =>
      operation.instruction is! JSR && operation.instruction is! JMP,
  };

  bool get addressIsCalculated => switch (operation.addressMode) {
    Implicit() ||
    Accumulator() ||
    Immediate() ||
    Relative() ||
    ZeroPage() ||
    Absolute() => false,

    ZeroPageX() ||
    ZeroPageY() ||
    AbsoluteX() ||
    AbsoluteY() ||
    Indirect() ||
    IndexedIndirect() ||
    IndirectIndexed() => true,
  };
}

class DebugCPU extends CPU {
  DebugCPU({required super.bus}) : super(eventBus: EventBus());

  @override
  int read(int address) => bus.cpuRead(address, disableSideEffects: true);

  @override
  void write(int address, int value) {}

  @override
  void handleOAMDMA() {}

  @override
  void handleDMCDMA() {}
}
