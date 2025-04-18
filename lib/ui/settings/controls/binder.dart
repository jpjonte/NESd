import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/nesd_theme.dart';
import 'package:nesd/ui/settings/controls/binder_controller.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';

class Binder extends ConsumerWidget {
  const Binder({required this.action, super.key});

  final InputAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(binderStateProvider(action));
    final controller = ref.watch(binderControllerProvider(action));

    final theme = Theme.of(context);

    final text =
        state.editing ? state.input?.label ?? '...' : state.input?.label ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: state.editing ? nesdRed[500] : nesdRed[800],
              borderRadius: BorderRadius.circular(8),
              border:
                  state.editing
                      ? Border.all(
                        color: theme.colorScheme.onPrimary,
                        width: 2.0,
                      )
                      : null,
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontVariations: [FontVariation.weight(700)],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child:
              state.input != null && !state.editing
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    iconSize: 16,
                    onPressed: controller.clearBinding,
                  )
                  : null,
        ),
      ],
    );
  }
}
