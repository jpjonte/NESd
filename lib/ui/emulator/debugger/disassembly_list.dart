import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/ui/common/clickable.dart';
import 'package:nesd/ui/common/context_menu.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/nesd_theme.dart';

final _defaultRowBorder = BorderSide(color: nesdRed.withAlpha(0), width: 2);
final _sectionBorder = BorderSide(color: debuggerColor, width: 2);
final _selectedBorder = BorderSide(color: Colors.yellow[800]!);
const _unselectedBorder = BorderSide(color: Colors.transparent);

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
      itemExtent: disassemblyRowHeight,
      itemCount: state.disassembly.length,
      itemBuilder: (context, index) {
        final line = state.disassembly[index];

        return DisassemblyRow(
          line: line,
          highlight: state.enabled && line.address == state.PC,
          breakpoint: state.breakpoints.firstWhereOrNull(
            (b) => b.address == line.address && !b.hidden,
          ),
          selected: line.address == state.selectedAddress,
          jumpTo: (address) {
            debugger.selectAddress(address);

            jumpTo(
              scrollController,
              calculateAddressScrollOffset(state, address),
            );
          },
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

class DisassemblyRow extends ConsumerWidget {
  const DisassemblyRow({
    required this.line,
    this.jumpTo,
    this.runTo,
    this.breakpoint,
    this.highlight = false,
    this.selected = false,
    super.key,
  });

  final DisassemblyLine line;
  final Breakpoint? breakpoint;
  final void Function(int)? jumpTo;
  final void Function(int)? runTo;
  final bool highlight;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);

    final address = line.address.toHex(width: 4);
    final opcode = line.opcode.toHex();
    final instruction = line.operation.instruction.name;
    final unofficial = line.operation.unofficial;
    final operands = line.operands.map((e) => e.toHex()).join(' ');

    final start = line.sectionStart;
    final end = line.sectionEnd;

    void select(int address) {
      debugger.selectAddress(address);
    }

    return ContextMenu(
      contextMenuBuilder: (_, close) => _buildContextMenu(debugger, close),
      child: Container(
        height: disassemblyRowHeight,
        decoration: BoxDecoration(
          color: highlight ? Colors.teal[800] : null,
          borderRadius: _buildBorderRadius(start, end),
          border: _buildBorder(start, end),
        ),
        child: Row(
          children: [
            BreakpointDot(line, breakpoint),
            Clickable(
              onTap: () => debugger.toggleBreakpointExists(line.address),
              child: Container(
                width: 36,
                height: disassemblyRowHeight,
                color: debuggerColor,
                child: Text(address, style: TextStyle(color: Colors.grey[400])),
              ),
            ),

            const VerticalDivider(),
            SizedBox(width: 32, child: Center(child: Text(opcode))),
            SizedBox(
              width: 42,
              child: Text(operands, style: TextStyle(color: Colors.grey[400])),
            ),
            const VerticalDivider(),
            Expanded(
              child: Clickable(
                onTap: () => select(line.address),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      selected ? _selectedBorder : _unselectedBorder,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              color:
                                  unofficial
                                      ? Colors.redAccent[100]
                                      : Colors.greenAccent[200],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        line.disassembly,
                        style: const TextStyle(color: Colors.orange),
                      ),
                      if (line.addressIsCalculated)
                        EffectiveAddressSegment(line: line),
                      if (line.isRead) ValueSegment(line),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContextMenu(
    DebuggerInterface debugger,
    VoidCallback close,
  ) {
    void toggleBreakpoint() => debugger.toggleBreakpointExists(line.address);
    void toggleBreakpointEnabled() =>
        debugger.toggleBreakpointEnabled(line.address);

    return [
      ListTile(
        title: Text(
          breakpoint != null ? 'Remove breakpoint' : 'Add breakpoint',
        ),
        onTap: () {
          close();
          toggleBreakpoint();
        },
      ),
      if (breakpoint case final breakpoint?)
        ListTile(
          title: Text(
            breakpoint.enabled ? 'Disable breakpoint' : 'Enable breakpoint',
          ),
          onTap: () {
            close();
            toggleBreakpointEnabled();
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
        title: Text('Go to ${line.readAddress.toHex(width: 4)}'),
        onTap: () {
          close();
          jumpTo?.call(line.readAddress);
        },
      ),
    ];
  }

  BorderRadius? _buildBorderRadius(bool start, bool end) {
    if (start) {
      return const BorderRadius.only(topRight: Radius.circular(4));
    }

    if (end) {
      return const BorderRadius.only(bottomRight: Radius.circular(4));
    }

    return null;
  }

  Border _buildBorder(bool start, bool end) {
    return Border(
      top: start ? _sectionBorder : BorderSide.none,
      bottom: end ? _sectionBorder : BorderSide.none,
      right: start || end ? _sectionBorder : _defaultRowBorder,
    );
  }
}

class EffectiveAddressSegment extends StatelessWidget {
  const EffectiveAddressSegment({required this.line, super.key});

  final DisassemblyLine line;

  @override
  Widget build(BuildContext context) {
    return Text(
      ' [\$${line.readAddress.toHex(width: 4)}]',
      style: const TextStyle(color: Colors.red),
    );
  }
}

class BreakpointDot extends ConsumerWidget {
  const BreakpointDot(this.line, this.breakpoint, {super.key});

  final DisassemblyLine line;
  final Breakpoint? breakpoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);

    final breakpoint = this.breakpoint;

    return Clickable(
      onTap: () => debugger.toggleBreakpointExists(line.address),
      child: Container(
        width: disassemblyRowHeight + 8,
        height: disassemblyRowHeight,
        color: debuggerColor,
        child:
            breakpoint != null
                ? Center(
                  child: Container(
                    width: disassemblyRowHeight - 4,
                    height: disassemblyRowHeight - 4,
                    decoration: BoxDecoration(
                      color: nesdRed.withAlpha(breakpoint.enabled ? 255 : 0),
                      shape: BoxShape.circle,
                      border: Border.all(color: nesdRed, width: 2),
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}

class ValueSegment extends ConsumerWidget {
  const ValueSegment(this.line, {super.key});

  final DisassemblyLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          const TextSpan(text: ' = ', style: TextStyle(color: Colors.grey)),
          TextSpan(
            text: '\$${debugger.read(line.readAddress).toHex()}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
