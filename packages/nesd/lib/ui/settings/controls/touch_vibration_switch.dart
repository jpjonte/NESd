import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class TouchVibrationSwitch extends ConsumerWidget {
  const TouchVibrationSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.touchVibration),
    );
    final touchControlsActive = ref.watch(
      settingsControllerProvider.select((s) => s.showTouchControls),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Touch vibration'),
        value: setting,
        enabled: touchControlsActive,
        onChanged: (value) => controller.touchVibration = value,
      ),
    );
  }
}
