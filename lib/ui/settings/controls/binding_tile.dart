import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/controls/binder.dart';
import 'package:nesd/ui/settings/controls/binder_controller.dart';
import 'package:nesd/ui/settings/controls/binder_state.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';

class BindingTile extends HookConsumerWidget {
  const BindingTile({required this.action, super.key});

  final InputAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(binderStateProvider(action));
    final controller = ref.watch(binderControllerProvider(action));
    final indexController = ref.watch(profileIndexProvider.notifier);

    final focusNode = useFocusNode();

    useListenable(focusNode);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => indexController.previous(),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => indexController.next(),
        ),
        SecondaryActionIntent: CallbackAction<SecondaryActionIntent>(
          onInvoke: (intent) => controller.clearBinding(),
        ),
      },
      child: FocusOnHover(
        focusNode: focusNode,
        onKeyEvent: controller.handleKeyEvent,
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            controller.editing = false;
          }
        },
        child: GestureDetector(
          onDoubleTap: controller.clearBinding,
          child: SettingsTile(
            adaptive: true,
            onTap: () => controller.editing = !state.editing,
            title: Text(action.title),
            child: Binder(action: action),
          ),
        ),
      ),
    );
  }
}
