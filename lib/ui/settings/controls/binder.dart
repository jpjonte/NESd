import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binder_controller.dart';
import 'package:nes/ui/settings/controls/binder_state.dart';

class Binder extends HookConsumerWidget {
  const Binder({
    required this.action,
    super.key,
  });

  final NesAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(binderStateProvider(action));
    final controller = ref.watch(binderControllerProvider(action));

    final theme = Theme.of(context);

    final focusNode = useFocusNode();

    final text =
        state.editing ? state.input?.label ?? '...' : state.input?.label ?? '';

    useListenable(focusNode);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: controller.handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          if (!state.editing) {
            focusNode.requestFocus();
          }

          controller.toggleEditing();
        },
        onDoubleTap: controller.clearBinding,
        child: SizedBox(
          width: 324,
          child: Row(
            children: [
              Container(
                width: 280,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withAlpha(state.editing ? 255 : 100),
                  borderRadius: BorderRadius.circular(4.0),
                  border: focusNode.hasFocus
                      ? Border.all(
                          color: theme.colorScheme.onPrimary,
                          width: 2.0,
                        )
                      : null,
                ),
                child: Center(child: Text(text, textAlign: TextAlign.center)),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                height: 40,
                child: state.input != null && !state.editing
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        iconSize: 16,
                        onPressed: controller.clearBinding,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
