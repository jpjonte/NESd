import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/hints/input_hint_bar.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/input/keyboard/keyboard_input_handler.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';

class NesdScaffold extends ConsumerWidget {
  const NesdScaffold({
    this.appBar,
    this.backgroundColor,
    this.body,
    this.hints = const [],
    this.hintColor,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? body;

  final List<InputHint> hints;

  final Color? hintColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardInputHandler = ref.watch(keyboardInputHandlerProvider);
    final inGame =
        ref.watch(emulatorActiveProvider) &&
        !ref.watch(toolFocusControllerProvider);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        final consumed = keyboardInputHandler.handleKeyEvent(event);

        if (inGame || consumed) {
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: FocusChild(
        autofocus: false,
        wrapAround: true,
        child: Scaffold(
          appBar: appBar,
          backgroundColor: backgroundColor,
          body: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => Navigator.of(context).maybePop(),
              ),
            },
            child: body ?? const SizedBox(),
          ),
          bottomNavigationBar: hints.isEmpty
              ? null
              : ExcludeFocus(
                  child: SafeArea(
                    top: false,
                    child: InputHintBar(
                      hints: hints,
                      color: hintColor,
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
