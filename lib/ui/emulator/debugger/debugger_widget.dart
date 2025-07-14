import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/extension/num_extension.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/emulator/debugger/action_bar.dart';
import 'package:nesd/ui/emulator/debugger/disassembly_list.dart';
import 'package:nesd/ui/emulator/debugger/status_bar.dart';
import 'package:nesd/ui/theme/base.dart';

const disassemblyRowHeight = 17.0;
final debuggerColor = nesdRed[750]!;

void jumpTo(
  ScrollController scrollController,
  double offset, {
  bool center = true,
}) {
  if (center &&
      scrollController.hasClients &&
      scrollController.position.hasViewportDimension) {
    final halfHeight = scrollController.position.viewportDimension / 2;

    scrollController.jumpTo(offset - halfHeight + disassemblyRowHeight);
  } else {
    scrollController.jumpTo(offset);
  }
}

double calculateAddressScrollOffset(DebuggerState state, int address) {
  return disassemblyRowHeight * _addressIndex(state, address);
}

int _addressIndex(DebuggerState state, int address) =>
    state.disassembly.indexWhere((e) => e.address == address);

const monoStyle = TextStyle(fontFamily: 'Ubuntu Mono', fontSize: 13);

class DebuggerWidget extends HookConsumerWidget {
  const DebuggerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    final state = ref.watch(debuggerNotifierProvider);

    ref.listen(debuggerNotifierProvider, (old, state) {
      if (!state.enabled || old?.PC == state.PC) {
        return;
      }

      final pcOffset = calculateAddressScrollOffset(state, state.PC);

      if (pcOffset < 0 || !scrollController.hasClients) {
        return;
      }

      final position = scrollController.position;

      if (!position.hasPixels || !position.hasViewportDimension) {
        return;
      }

      final offset = scrollController.offset;
      final viewportEnd =
          offset + position.viewportDimension - disassemblyRowHeight;

      // previous list index based on scroll offset
      final scrollIndex = (offset / disassemblyRowHeight).floor();
      // current list index based on previous PC and current list
      final lastIndex = _addressIndex(state, old?.PC ?? 0);
      final indexChanged = scrollIndex != lastIndex;

      final pcOutOfBounds = !pcOffset.inRange(offset, viewportEnd);

      if (pcOutOfBounds) {
        jumpTo(scrollController, pcOffset);
      } else if (indexChanged) {
        // the list index for the current scroll position changed,
        // so items were added to the list before the current PC
        jumpTo(
          scrollController,
          scrollIndex * disassemblyRowHeight + 1,
          center: false,
        );
      }
    });

    return DefaultTextStyle(
      style: monoStyle,
      child: DividerTheme(
        data: Theme.of(context).dividerTheme.copyWith(color: debuggerColor),
        child: Expanded(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionBar(scrollController: scrollController),
                  const StatusBar(),
                  Expanded(
                    child: DisassemblyList(scrollController: scrollController),
                  ),
                ],
              ),
              if (state.showStack)
                Positioned(
                  left: 175,
                  top: 100,
                  child: StackTooltip(stack: state.stack),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StackTooltip extends StatelessWidget {
  const StackTooltip({required this.stack, super.key});

  final List<int> stack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      width: 60,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: DefaultTextStyle(
        style: monoStyle,
        child: Column(
          children: [
            for (final item in stack) Text('0x${item.toHex()}'),
            if (stack.isEmpty)
              const Text(
                'Empty',
                style: TextStyle(
                  color: Colors.grey,
                  fontVariations: [FontVariation.italic(1.0)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
