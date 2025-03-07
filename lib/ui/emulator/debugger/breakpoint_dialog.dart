// raw strings are used to avoid escaping backslashes in regexes
// ignore_for_file: unnecessary_raw_strings

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';

class BreakpointDialog extends ConsumerWidget {
  const BreakpointDialog({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debuggerState = ref.watch(debuggerNotifierProvider);

    return AlertDialog(
      title: const Text('Breakpoints'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final breakpoint in debuggerState.breakpoints)
              if (!breakpoint.hidden)
                BreakpointRow(
                  breakpoint: breakpoint,
                  scrollController: scrollController,
                ),
            const AddBreakpointWidget(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BreakpointRow extends ConsumerWidget {
  const BreakpointRow({
    required this.breakpoint,
    required this.scrollController,
    super.key,
  });

  final Breakpoint breakpoint;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);
    final state = ref.watch(debuggerNotifierProvider);

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: breakpoint.enabled,
              onChanged:
                  (_) => debugger.toggleBreakpointEnabled(breakpoint.address),
            ),
            const SizedBox(width: 8),
            Text(
              breakpoint.address.toHex(width: 4),
              style: monoStyle.copyWith(
                fontSize: 15,
                color: breakpoint.enabled ? null : Colors.grey,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.gps_fixed),
              tooltip: 'Go to address',
              onPressed: () {
                final pcOffset = calculateAddressScrollOffset(
                  state,
                  breakpoint.address,
                );

                jumpTo(scrollController, pcOffset);

                Navigator.of(context).pop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Remove breakpoint',
              onPressed: () => debugger.removeBreakpoint(breakpoint),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 32),
            Checkbox(
              value: breakpoint.disableOnHit,
              onChanged: (_) {
                breakpoint.disableOnHit = !breakpoint.disableOnHit;

                debugger.updateBreakpoint(breakpoint);
              },
            ),
            const SizedBox(width: 4),
            const Text('Disable on hit', style: TextStyle(fontSize: 15)),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 32),
            Checkbox(
              value: breakpoint.removeOnHit,
              onChanged: (_) {
                breakpoint.removeOnHit = !breakpoint.removeOnHit;

                debugger.updateBreakpoint(breakpoint);
              },
            ),
            const SizedBox(width: 4),
            const Text('Remove on hit', style: TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }
}

class AddBreakpointWidget extends HookConsumerWidget {
  const AddBreakpointWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugger = ref.watch(debuggerProvider);

    final controller = useTextEditingController();

    final focusNode = useFocusNode();

    void submit() {
      final address = int.tryParse(controller.text, radix: 16);

      if (address != null) {
        debugger.addBreakpoint(Breakpoint(address));
        controller.clear();
        focusNode.requestFocus();
      }
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            onChanged: (_) {
              var text = controller.text;

              if (text.length > 4) {
                text = text.substring(0, 4);
              }

              if (text.contains(RegExp(r'[^0-9a-fA-F]'))) {
                text = text.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
              }

              controller
                ..value = TextEditingValue(text: text.toUpperCase())
                ..selection = TextSelection.collapsed(offset: text.length);
            },
            onSubmitted: (_) => submit(),
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: '0000',
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: submit),
      ],
    );
  }
}
