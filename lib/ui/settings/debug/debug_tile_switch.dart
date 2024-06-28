import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class DebugTileSwitch extends ConsumerWidget {
  const DebugTileSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.showTiles));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Show Tiles'),
      value: setting,
      onChanged: (value) => controller.showTiles = value,
    );
  }
}
