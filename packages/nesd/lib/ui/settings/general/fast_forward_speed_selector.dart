import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/segmented_settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

extension on FastForwardSpeed {
  String get label => switch (this) {
    FastForwardSpeed.x2 => '2×',
    FastForwardSpeed.x3 => '3×',
    FastForwardSpeed.x4 => '4×',
    FastForwardSpeed.max => 'Max',
  };
}

class FastForwardSpeedSelector extends ConsumerWidget {
  const FastForwardSpeedSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.fastForwardSpeed),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SegmentedSettingsTile<FastForwardSpeed>(
        title: const Text('Fast Forward Speed'),
        values: FastForwardSpeed.values,
        value: setting,
        onChanged: (value) => controller.fastForwardSpeed = value,
        label: (value) => value.label,
      ),
    );
  }
}
