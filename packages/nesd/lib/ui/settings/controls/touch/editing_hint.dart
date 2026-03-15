import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';
import 'package:nesd/ui/theme/base.dart';

class EditingHint extends ConsumerWidget {
  const EditingHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(touchEditorStateProvider);
    final controller = ref.watch(touchEditorStateProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(200),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTap: () => controller.hideHint(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BackButton(),
              if (state.showHint) const Expanded(child: HintText()),
              if (state.showHint) const SizedBox(width: 8),
              if (state.showHint)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close, size: 16),
                ),
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
            style: DefaultTextStyle.of(context).style,
            children: [
              BoldSpan('Tap'),
              const TextSpan(text: ' to edit controls. '),
              BoldSpan('Drag'),
              const TextSpan(text: ' to move controls. '),
              BoldSpan('Rotate'),
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
  BoldSpan(String text)
    : super(
        text: text,
        style: baseTextStyle.copyWith(
          fontVariations: const [FontVariation.weight(700)],
        ),
      );
}
