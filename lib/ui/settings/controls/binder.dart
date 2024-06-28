import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/extension/iterable_extension.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binding.dart';
import 'package:nes/ui/settings/controls/gamepad_input.dart';
import 'package:nes/ui/settings/settings.dart';

class Binder extends HookConsumerWidget {
  const Binder({
    required this.action,
    required this.binding,
    super.key,
  });

  final NesAction action;

  final InputCombination? binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);

    final theme = Theme.of(context);

    final newBinding = useState<InputCombination?>(null);

    final focusNode = useFocusNode();

    final editing = useState(false);

    useOnStreamChange(
      Gamepads.events,
      onData: (event) {
        if (!editing.value) {
          return;
        }

        final updatedBinding = newBinding.value ??
            InputCombination.gamepad(
              gamepadId: event.gamepadId,
              gamepadName: event.gamepadName,
              inputs: const {},
            );

        if (updatedBinding is! GamepadInputCombination) {
          return;
        }

        if (event.gamepadId != updatedBinding.gamepadId) {
          return;
        }

        final gamepadInputAction = updatedBinding.inputs.firstWhereOrNull(
          (input) => input.id == event.key,
        );

        if (event.value.abs() > 0.5) {
          newBinding.value = updatedBinding.copyWith(
            inputs: {
              ...updatedBinding.inputs,
              GamepadInput(
                id: event.key,
                direction: event.value.sign.toInt(),
                label: event.label,
              ),
            },
          );
        } else if (gamepadInputAction != null) {
          focusNode.unfocus();

          editing.value = false;

          controller.updateBinding(action, updatedBinding);
        }
      },
    );

    return Focus(
      focusNode: focusNode,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyRepeatEvent) {
          return KeyEventResult.handled;
        }

        final updatedBinding =
            newBinding.value ?? const InputCombination.keyboard({});

        if (updatedBinding is! KeyboardInputCombination) {
          return KeyEventResult.ignored;
        }

        if (event is KeyDownEvent) {
          newBinding.value = updatedBinding.copyWith(
            keys: {
              ...updatedBinding.keys,
              event.logicalKey,
            },
          );

          return KeyEventResult.handled;
        }

        if (event is KeyUpEvent) {
          focusNode.unfocus();

          editing.value = false;

          controller.updateBinding(action, updatedBinding);
        }

        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final text = editing.value
              ? (newBinding.value != null ? newBinding.value!.label : '...')
              : binding?.label ?? '';

          return GestureDetector(
            onTap: () {
              if (editing.value) {
                editing.value = false;

                focusNode.unfocus();
              } else {
                editing.value = true;

                newBinding.value = null;

                focusNode.requestFocus();
              }
            },
            onDoubleTap: () {
              focusNode.unfocus();

              editing.value = false;

              controller.clearKeyBinding(action);
            },
            child: Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withAlpha(editing.value ? 255 : 100),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(child: Text(text, textAlign: TextAlign.center)),
            ),
          );
        },
      ),
    );
  }
}
