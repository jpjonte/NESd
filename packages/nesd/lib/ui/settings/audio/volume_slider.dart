import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.volume),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SliderSettingsTile(
        label: 'Volume',
        onTap: () => controller.volume = 0.5,
        onChanged: (value) => controller.volume = value,
        value: setting,
        displayValue: (setting * 100).toStringAsFixed(0),
        step: 0.05,
      ),
    );
  }
}
