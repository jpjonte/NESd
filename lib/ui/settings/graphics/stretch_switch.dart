import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class StretchSwitch extends ConsumerWidget {
  const StretchSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.stretch));
    final controller = ref.read(settingsControllerProvider.notifier);

    return SwitchListTile(
      title: const Text('Stretch screen'),
      value: setting,
      onChanged: (value) => controller.stretch = value,
    );
  }
}
