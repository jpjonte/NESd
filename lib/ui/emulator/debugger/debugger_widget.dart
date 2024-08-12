import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/extension/num_extension.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/emulator/debugger/action_bar.dart';
import 'package:nesd/ui/emulator/debugger/disassembly_list.dart';
import 'package:nesd/ui/emulator/debugger/status_bar.dart';
import 'package:nesd/ui/nesd_theme.dart';

const debuggerRowHeight = 20.0;

void jumpTo(ScrollController scrollController, double offset) {
  if (scrollController.hasClients &&
      scrollController.position.hasViewportDimension) {
    final halfHeight = scrollController.position.viewportDimension / 2;

    scrollController.jumpTo(offset - halfHeight + debuggerRowHeight);
  } else {
    scrollController.jumpTo(offset);
  }
}

double calculateAddressScrollOffset(DebuggerState state, int address) {
  return debuggerRowHeight *
      state.disassembly.indexWhere((e) => e.address == address);
}

const monoStyle = TextStyle(fontFamily: 'Ubuntu Mono');

class DebuggerWidget extends HookConsumerWidget {
  const DebuggerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    ref.listen(debuggerNotifierProvider, (old, state) {
      if (old?.PC == state.PC) {
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
          offset + position.viewportDimension - debuggerRowHeight;

      final update = !pcOffset.inRange(offset, viewportEnd);

      if (update) {
        jumpTo(scrollController, pcOffset);
      }
    });

    return DefaultTextStyle(
      style: monoStyle,
      child: DividerTheme(
        data: Theme.of(context).dividerTheme.copyWith(color: nesdRed[700]),
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionBar(scrollController: scrollController),
              const StatusBar(),
              Expanded(
                child: DisassemblyList(scrollController: scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
