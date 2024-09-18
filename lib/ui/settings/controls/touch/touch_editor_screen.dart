import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/settings/controls/touch/action_buttons.dart';
import 'package:nesd/ui/settings/controls/touch/editing_hint.dart';
import 'package:nesd/ui/settings/controls/touch/editor_popup.dart';
import 'package:nesd/ui/settings/controls/touch/placeholder_display.dart';
import 'package:nesd/ui/settings/controls/touch/touch_controls_editor_view.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

@RoutePage()
class TouchEditorScreen extends ConsumerWidget {
  const TouchEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(touchEditorNotifierProvider);

    return SafeArea(
      child: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return TouchArea(
                  constraints: constraints,
                  child: Stack(
                    children: [
                      const PlaceholderDisplay(),
                      TouchControlsEditorView(orientation: orientation),
                      if (state.editingConfig case final config?)
                        if (state.editingIndex == null)
                          TouchControl(config: config),
                      const EditingHint(),
                      ActionButtons(orientation: orientation),
                      EditorPopup(orientation: orientation),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
