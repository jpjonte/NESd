import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binding_tile.dart';
import 'package:nes/ui/settings/settings.dart';

class ControlsSettings extends ConsumerWidget {
  const ControlsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindings = ref.watch(
      settingsControllerProvider.select((s) => s.bindings),
    );

    return ListView(
      children: [
        for (final action in allActions)
          BindingTile(
            action: action,
            binding: bindings[action],
          ),
      ],
    );
  }
}
