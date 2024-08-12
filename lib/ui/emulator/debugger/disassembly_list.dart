import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/nesd_theme.dart';

class DisassemblyList extends ConsumerWidget {
  const DisassemblyList({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return ListView.builder(
      controller: scrollController,
      itemExtent: debuggerRowHeight,
      itemCount: state.disassembly.length,
      itemBuilder: (context, index) {
        final line = state.disassembly[index];

        return DisassemblyRow(
          line: line,
          highlight: line.address == state.PC,
          breakpoint: state.breakpoints
              .any((e) => e.address == line.address && !e.hidden),
          onTap: () => debugger.toggleBreakpoint(line.address),
        );
      },
    );
  }
}

class DisassemblyRow extends StatelessWidget {
  const DisassemblyRow({
    required this.line,
    this.onTap,
    this.breakpoint = false,
    this.highlight = false,
    super.key,
  });

  final DisassemblyLine line;
  final bool highlight;
  final bool breakpoint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final address = line.address.toHex(width: 4);
    final opcode = line.opcode.toHex();
    final instruction = line.operation.instruction.name;
    final operands = line.operands.map((e) => e.toHex()).join(' ');

    final start = line.sectionStart;
    final end = line.sectionEnd;

    final defaultBorder = BorderSide(color: nesdRed.withAlpha(0), width: 2);
    final sectionBorder = BorderSide(color: nesdRed[700]!, width: 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: debuggerRowHeight,
        decoration: BoxDecoration(
          color: highlight ? Colors.teal[800] : null,
          borderRadius: start
              ? const BorderRadius.vertical(top: Radius.circular(4))
              : end
                  ? const BorderRadius.vertical(bottom: Radius.circular(4))
                  : null,
          border: Border(
            top: start ? sectionBorder : BorderSide.none,
            bottom: end ? sectionBorder : BorderSide.none,
            left: start || end ? sectionBorder : defaultBorder,
            right: start || end ? sectionBorder : defaultBorder,
          ),
        ),
        child: Row(
          children: [
            BreakpointDot(enabled: breakpoint),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Text(address, style: TextStyle(color: Colors.grey[400])),
            ),
            const VerticalDivider(),
            const SizedBox(width: 12),
            SizedBox(width: 16, child: Text(opcode)),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(operands, style: TextStyle(color: Colors.grey[400])),
            ),
            const VerticalDivider(),
            const SizedBox(width: 12),
            Text(
              instruction,
              style: TextStyle(color: Colors.greenAccent[200]),
            ),
            const SizedBox(width: 12),
            Text(
              line.disassembledOperands,
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class BreakpointDot extends StatelessWidget {
  const BreakpointDot({
    required this.enabled,
    super.key,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: debuggerRowHeight,
      child: enabled
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: nesdRed,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
