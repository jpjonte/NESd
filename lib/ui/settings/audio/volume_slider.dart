import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.volume));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Volume'),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Slider(
          value: setting,
          onChanged: (value) => controller.volume = value,
          label: 'Volume',
        ),
      ),
    );
  }
}
