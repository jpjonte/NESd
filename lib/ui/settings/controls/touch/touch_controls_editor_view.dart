import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class TouchControlsEditorView extends HookConsumerWidget {
  const TouchControlsEditorView({required this.orientation, super.key});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = useState<Offset>(Offset.zero);

    final editorController = ref.watch(touchEditorNotifierProvider.notifier);

    final moveController = ref.watch(touchEditorMoveIndexProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) async {
            editorController.edit(
              orientation,
              constraints.biggest,
              details.localPosition,
            );
          },
          onPanStart: (details) {
            final rect = moveController.startMoving(
              orientation,
              constraints.biggest,
              details.localPosition,
            );

            if (rect != null) {
              offset.value = rect.center - details.localPosition;
            }
          },
          onPanUpdate: (details) {
            moveController.updateMovement(
              orientation,
              constraints.biggest,
              details.localPosition + offset.value,
            );
          },
          onPanEnd: (details) => moveController.stopMoving(),
          child: const AbsorbPointer(child: TouchControlsBuilder()),
        );
      },
    );
  }
}
