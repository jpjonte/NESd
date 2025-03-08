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
Disassembler disassembler(Ref ref) {
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

class Disassembler {
  Disassembler({required this.eventBus, required this.cpu}) {
    final bus =
        Bus(cpu.bus.cartridge)
          ..ppu = cpu.bus.ppu
          ..apu = cpu.bus.apu;

    debugCpu = CPU(eventBus: eventBus, bus: bus, disableSideEffects: true)
      ..state = cpu.state;

    bus.cpu = debugCpu;

    _search([
      DisassemblerSearchNode(debugCpu.read16(resetVector), entrypoint: true),
      DisassemblerSearchNode(debugCpu.read16(nmiVector), entrypoint: true),
      DisassemblerSearchNode(debugCpu.read16(irqVector), entrypoint: true),
    ]);
  }

  static const depthLimit = 200;

  final EventBus eventBus;
  final CPU cpu;
  late final CPU debugCpu;

  final Map<int, DisassemblyLine> lines = {};

  Disassembly update() {
    debugCpu.state = cpu.state;

    _search([DisassemblerSearchNode(cpu.PC)]);

    return lines.values.toList()
      ..sort((a, b) => a.address.compareTo(b.address));
  }

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

    final readAddress = _getReadAddress(op, address);

    final value = debugCpu.read(readAddress);

    final disassembledOperands = _disassemble(op, operands, readAddress, value);

    final line = DisassemblyLine(
      address: address,
      opcode: opcode,
      operation: op,
      operands: operands,
      disassembledOperands: disassembledOperands,
      readAddress: readAddress,
      sectionStart: isEntrypoint || lines[address]?.sectionStart == true,
      sectionEnd:
          op.instruction == RTS ||
          op.instruction == RTI ||
          op.instruction == JMP ||
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

  int _getReadAddress(Operation op, int address) {
    final previousPc = debugCpu.PC;

    debugCpu.PC = address + 1;

    final pipeline = op.addressMode.pipeline(
      read: op.instruction.isRead,
      write: op.instruction.isWrite,
    );

    for (final cycle in pipeline) {
      cycle(debugCpu);
    }

    debugCpu.PC = previousPc;

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
      ZeroPage() =>
        '\$${operands[0].toHex()}'
            ' = \$${value.toHex()}',
      ZeroPageX() =>
        '\$${operands[0].toHex()},X'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      ZeroPageY() =>
        '\$${operands[0].toHex()},Y'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      Relative() => '\$${readAddress.toHex(width: 4)}',
      Absolute() => _disassembleAbsolute(readAddress, op),
      AbsoluteX() =>
        '\$${((readAddress - debugCpu.X) & 0xffff).toHex(width: 4)},X'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      AbsoluteY() =>
        '\$${((readAddress - debugCpu.Y) & 0xffff).toHex(width: 4)},Y'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      Indirect() =>
        '(\$${operands[1].toHex()}${operands[0].toHex()})'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      IndexedIndirect() =>
        '(\$${operands[0].toHex()},X)'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
      IndirectIndexed() =>
        '(\$${operands[0].toHex()}),Y'
            ' [\$${readAddress.toHex(width: 4)}]'
            ' = \$${value.toHex()}',
    };
  }

  String _disassembleAbsolute(int address, Operation op) {
    final buffer = StringBuffer('\$${address.toHex(width: 4)}');

    if (op.instruction != JSR && op.instruction != JMP) {
      buffer.write(' = \$${debugCpu.read(address).toHex()}');
    }

    return buffer.toString();
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

      if (op.instruction != JMP &&
          op.instruction != RTS &&
          op.instruction != RTI) {
        children.add(DisassemblerSearchNode(next, depth: current.depth + 1));
      }

      if (op.instruction.type == InstructionType.branch ||
          op.instruction.type == InstructionType.jump) {
        children.add(
          DisassemblerSearchNode(
            line.readAddress,
            entrypoint:
                op.instruction == JSR ||
                op.instruction == BRK ||
                op.instruction == JMP,
            depth: current.depth + 1,
          ),
        );
      }

      if (op.instruction == BRK) {
        children.add(
          DisassemblerSearchNode(
            debugCpu.read16(irqVector),
            entrypoint: true,
            depth: current.depth + 1,
          ),
        );
      }

      for (final child in children) {
        if (child.depth < depthLimit &&
            !visited.contains(child.pc) &&
            child.pc <= 0xffff) {
          visited.add(child.pc);
          queue.add(child);
        }
      }
    }
  }
}

class DummyDisassembler implements Disassembler {
  @override
  Disassembly update() {
    return [];
  }

  @override
  void _search(List<DisassemblerSearchNode> queue) {}

  @override
  CPU get cpu => throw UnimplementedError();

  @override
  CPU get debugCpu => throw UnimplementedError();

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

  @override
  int _getReadAddress(Operation op, int address) {
    throw UnimplementedError();
  }

  @override
  String _disassemble(
    Operation op,
    List<int> operands,
    int readAddress,
    int value,
  ) {
    throw UnimplementedError();
  }

  @override
  String _disassembleAbsolute(int address, Operation op) {
    throw UnimplementedError();
  }

  @override
  set debugCpu(CPU debugCpu) {}

  @override
  EventBus get eventBus => throw UnimplementedError();
}

class DisassemblyLine {
  const DisassemblyLine({
    required this.address,
    required this.opcode,
    required this.operation,
    required this.operands,
    required this.disassembledOperands,
    required this.readAddress,
    required this.sectionStart,
    required this.sectionEnd,
  });

  final int address;
  final int opcode;
  final Operation operation;
  final List<int> operands;
  final String disassembledOperands;
  final int readAddress;
  final bool sectionStart;
  final bool sectionEnd;
}
