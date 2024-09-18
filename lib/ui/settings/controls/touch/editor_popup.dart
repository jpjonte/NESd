import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/settings/controls/touch/forms/touch_input_form.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class EditorPopup extends ConsumerWidget {
  const EditorPopup({required this.orientation, super.key});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(touchEditorNotifierProvider);
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    final config = state.editingConfig;

    if (config == null) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () => controller.close(),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withAlpha(230),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.only(
            left: 16,
            top: 8,
            right: 16,
            bottom: 16,
          ),
          width: 350,
          child: TouchInputForm(
            orientation: orientation,
            config: config,
            index: state.editingIndex,
          ),
        ),
      ),
    );
  }
}
