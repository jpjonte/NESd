import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/operation.dart';

typedef Disassembly = List<DisassemblyLine>;

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
  Disassembler({
    required this.cpu,
  }) : debugCpu = CPU(cpu.bus, debug: true)..state = cpu.state {
    _search([
      DisassemblerSearchNode(debugCpu.read16(resetVector)),
      DisassemblerSearchNode(debugCpu.read16(nmiVector)),
      DisassemblerSearchNode(debugCpu.read16(irqVector)),
    ]);
  }

  final CPU cpu;
  final CPU debugCpu;

  final Map<int, DisassemblyLine> lines = {};

  Disassembly update() {
    debugCpu.state = cpu.state;

    _search([
      DisassemblerSearchNode(cpu.PC),
    ]);

    return lines.values.toList()
      ..sort((a, b) => a.address.compareTo(b.address));
  }

  void _search(List<DisassemblerSearchNode> queue) {
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      final pc = current.pc;

      visited.add(pc);

      final opcode = debugCpu.read(pc);

      final op = ops[opcode];

      if (op == null) {
        continue;
      }

      final operandCount = op.addressMode.operandCount;

      final operands = List.generate(
        operandCount,
        (index) => debugCpu.read(pc + 1 + index),
        growable: false,
      );

      final (address, _) = op.addressMode.read(debugCpu, pc + 1);

      final disassembledOperands = op.addressMode.debug(
        debugCpu,
        pc + 1,
        operands,
        address,
      );

      final line = DisassemblyLine(
        address: pc,
        opcode: opcode,
        operation: op,
        operands: operands,
        disassembledOperands: disassembledOperands,
        sectionStart: current.entrypoint,
        sectionEnd: op.instruction == RTS || op.instruction == RTI,
      );

      lines[pc] = line;

      for (var i = 1; i <= operandCount; i++) {
        final next = pc + i;

        if (lines.containsKey(next)) {
          lines.remove(next);
        }
      }

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
            address,
            entrypoint: op.instruction == JSR || op.instruction == BRK,
            depth: current.depth + 1,
          ),
        );
      }

      for (final child in children) {
        if (child.depth < 100 &&
            !visited.contains(child.pc) &&
            child.pc <= 0xffff) {
          queue.add(child);
        }
      }
    }
  }
}

class DisassemblyLine {
  const DisassemblyLine({
    required this.address,
    required this.opcode,
    required this.operation,
    required this.operands,
    required this.disassembledOperands,
    required this.sectionStart,
    required this.sectionEnd,
  });

  final int address;
  final int opcode;
  final Operation operation;
  final List<int> operands;
  final String disassembledOperands;
  final bool sectionStart;
  final bool sectionEnd;
}
