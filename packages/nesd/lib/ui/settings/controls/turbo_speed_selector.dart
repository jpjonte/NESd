import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/segmented_settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

extension on TurboSpeed {
  String get label => switch (this) {
    TurboSpeed.x1 => '30 Hz',
    TurboSpeed.x2 => '15 Hz',
    TurboSpeed.x3 => '10 Hz',
    TurboSpeed.x4 => '7.5 Hz',
  };
}

class TurboSpeedSelector extends ConsumerWidget {
  const TurboSpeedSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.turboSpeed),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SegmentedSettingsTile<TurboSpeed>(
        title: const Text('Turbo Speed'),
        values: TurboSpeed.values,
        value: setting,
        onChanged: (value) => controller.turboSpeed = value,
        label: (value) => value.label,
      ),
    );
  }
}
