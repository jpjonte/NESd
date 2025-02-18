import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class EditingHint extends ConsumerWidget {
  const EditingHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(touchEditorNotifierProvider);
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) => GestureDetector(
              onTap: () => controller.hideHint(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BackButton(),
                  if (state.showHint) const Expanded(child: HintText()),
                  if (state.showHint) const SizedBox(width: 8),
                  if (state.showHint) const Icon(Icons.close, size: 16),
                ],
              ),
            ),
      ),
    );
  }
}

class HintText extends StatelessWidget {
  const HintText({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return RichText(
          text: TextSpan(
            children: [
              const BoldSpan('Tap'),
              const TextSpan(text: ' to edit controls. '),
              const BoldSpan('Drag'),
              const TextSpan(text: ' to move controls. '),
              const BoldSpan('Rotate'),
              const TextSpan(text: ' your device to edit the '),
              BoldSpan(
                orientation == Orientation.portrait ? 'landscape' : 'portrait',
              ),
              const TextSpan(text: ' layout.'),
            ],
          ),
        );
      },
    );
  }
}

class BoldSpan extends TextSpan {
  const BoldSpan(String text)
    : super(text: text, style: const TextStyle(fontWeight: FontWeight.bold));
}
