import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/debug_overlay.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/input/keyboard/keyboard_input_handler.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';

class EmulatorWidget extends ConsumerWidget {
  static const menuKey = Key('menu');

  const EmulatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final keyboardInputHandler = ref.watch(keyboardInputHandlerProvider);

    final theme = Theme.of(context);

    return Stack(
      children: [
        Focus(
          autofocus: true,
          onKeyEvent:
              (focusNode, event) =>
                  keyboardInputHandler.handleKeyEvent(event)
                      ? KeyEventResult.handled
                      : KeyEventResult.ignored,
          child: const FrameBufferStreamBuilder(),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Theme(
              data: theme.copyWith(
                iconButtonTheme: IconButtonThemeData(
                  style: theme.iconButtonTheme.style!.copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.black.withAlpha(150),
                    ),
                  ),
                ),
              ),
              child: IconButton(
                key: menuKey,
                icon: const Icon(Icons.menu),
                color: Colors.white,
                onPressed:
                    () => ref.read(routerProvider).navigate(const MenuRoute()),
              ),
            ),
          ),
        ),
        if (settings.showDebugOverlay) const DebugOverlay(),
        if (settings.showTouchControls) const TouchControlsBuilder(),
      ],
    );
  }
}
