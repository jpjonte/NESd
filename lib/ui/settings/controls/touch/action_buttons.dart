import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/settings/controls/touch/touch_editor_state.dart';

class ActionButtons extends ConsumerWidget {
  const ActionButtons({
    required this.orientation,
    super.key,
  });

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(touchEditorNotifierProvider.notifier);

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'reset',
              child: const Icon(Icons.restart_alt),
              onPressed: () {
                // open confirmation dialog
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reset Layout'),
                    content: const Text(
                      'Are you sure you want to reset the layout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.reset(orientation);
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'add',
              child: const Icon(Icons.add),
              onPressed: () => controller.add(orientation),
            ),
          ],
        ),
      ),
    );
  }
}
