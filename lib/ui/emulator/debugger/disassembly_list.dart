import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/ui/common/context_menu.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/nesd_theme.dart';

class DisassemblyList extends ConsumerWidget {
  const DisassemblyList({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);
    final state = ref.watch(debuggerNotifierProvider);
    final nesController = ref.read(nesControllerProvider);

    return ListView.builder(
      controller: scrollController,
      itemExtent: debuggerRowHeight,
      itemCount: state.disassembly.length,
      itemBuilder: (context, index) {
        final line = state.disassembly[index];

        return DisassemblyRow(
          line: line,
          highlight: line.address == state.PC,
          breakpoint: state.breakpoints.firstWhereOrNull(
            (b) => b.address == line.address && !b.hidden,
          ),
          toggleBreakpoint: () => debugger.toggleBreakpointExists(line.address),
          toggleBreakpointEnabled:
              () => debugger.toggleBreakpointEnabled(line.address),
          jumpTo:
              (address) => jumpTo(
                scrollController,
                calculateAddressScrollOffset(state, address),
              ),
          runTo: (address) {
            debugger.addBreakpoint(
              Breakpoint(address, hidden: true, removeOnHit: true),
            );

            nesController.unpause();
          },
        );
      },
    );
  }
}

class DisassemblyRow extends StatelessWidget {
  const DisassemblyRow({
    required this.line,
    this.toggleBreakpoint,
    this.toggleBreakpointEnabled,
    this.jumpTo,
    this.runTo,
    this.breakpoint,
    this.highlight = false,
    super.key,
  });

  final DisassemblyLine line;
  final bool highlight;
  final Breakpoint? breakpoint;
  final VoidCallback? toggleBreakpoint;
  final VoidCallback? toggleBreakpointEnabled;
  final void Function(int)? jumpTo;
  final void Function(int)? runTo;

  @override
  Widget build(BuildContext context) {
    final address = line.address.toHex(width: 4);
    final opcode = line.opcode.toHex();
    final instruction = line.operation.instruction.name;
    final unofficial = line.operation.unofficial;
    final operands = line.operands.map((e) => e.toHex()).join(' ');

    final start = line.sectionStart;
    final end = line.sectionEnd;

    final defaultBorder = BorderSide(color: nesdRed.withAlpha(0), width: 2);
    final sectionBorder = BorderSide(color: nesdRed[700]!, width: 2);

    return GestureDetector(
      onTap: toggleBreakpoint,
      child: ContextMenu(
        contextMenuBuilder:
            (context, close) => [
              ListTile(
                title: Text(
                  breakpoint != null ? 'Remove breakpoint' : 'Add breakpoint',
                ),
                onTap: () {
                  close();
                  toggleBreakpoint?.call();
                },
              ),
              if (breakpoint case final breakpoint?)
                ListTile(
                  title: Text(
                    breakpoint.enabled
                        ? 'Disable breakpoint'
                        : 'Enable breakpoint',
                  ),
                  onTap: () {
                    close();
                    toggleBreakpointEnabled?.call();
                  },
                ),
              ListTile(
                title: Text('Run to ${line.address.toHex(width: 4)}'),
                onTap: () {
                  close();
                  runTo?.call(line.address);
                },
              ),
              ListTile(
                title: Text('Jump to ${line.readAddress.toHex(width: 4)}'),
                onTap: () {
                  close();
                  jumpTo?.call(line.readAddress);
                },
              ),
            ],
        child: Container(
          height: debuggerRowHeight,
          decoration: BoxDecoration(
            color: highlight ? Colors.teal[800] : null,
            borderRadius:
                start
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
              BreakpointDot(breakpoint),
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
                child: Text(
                  operands,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const VerticalDivider(),
              const SizedBox(width: 12),
              Text(
                instruction,
                style: TextStyle(
                  color:
                      unofficial
                          ? Colors.redAccent[100]
                          : Colors.greenAccent[200],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                line.disassembledOperands,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreakpointDot extends StatelessWidget {
  const BreakpointDot(this.breakpoint, {super.key});

  final Breakpoint? breakpoint;

  @override
  Widget build(BuildContext context) {
    final breakpoint = this.breakpoint;

    return SizedBox(
      width: debuggerRowHeight,
      child:
          breakpoint != null
              ? Center(
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: nesdRed.withAlpha(breakpoint.enabled ? 255 : 0),
                    shape: BoxShape.circle,
                    border: Border.all(color: nesdRed, width: 2),
                  ),
                ),
              )
              : null,
    );
  }
}
