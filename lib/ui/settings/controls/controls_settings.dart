import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/input/action/all_actions.dart';
import 'package:nes/ui/settings/controls/binding_tile.dart';
import 'package:nes/ui/settings/settings.dart';

class ControlsSettings extends HookConsumerWidget {
  const ControlsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(
      settingsControllerProvider.select((s) => s.bindings),
    );

    final index = useState(0);

    final maxIndex = bindings.values.fold(
      0,
      (acc, inputs) => max(acc, inputs.length - 1),
    );

    return ListView(
      children: [
        ListTile(
          trailing: SizedBox(
            width: 300,
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: index.value > 0
                      ? IconButton(
                          onPressed: () => index.value--,
                          icon: const Icon(Icons.keyboard_arrow_left),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Center(
                  child: Text(
                    'Profile ${index.value + 1}',
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: index.value <= maxIndex
                      ? IconButton(
                          onPressed: () =>
                              index.value = min(index.value + 1, maxIndex + 1),
                          icon: Icon(
                            index.value == maxIndex
                                ? Icons.add
                                : Icons.keyboard_arrow_right,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        for (final action in allActions)
          BindingTile(
            action: action,
            index: index.value,
            inputs: bindings[action] ?? [],
          ),
      ],
    );
  }
}
