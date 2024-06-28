import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class BorderSwitch extends ConsumerWidget {
  const BorderSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.showBorder));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Show Border'),
      value: setting,
      onChanged: (value) => controller.showBorder = value,
    );
  }
}
