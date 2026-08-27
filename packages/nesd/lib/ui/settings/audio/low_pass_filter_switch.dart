import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class LowPassFilterSwitch extends ConsumerWidget {
  const LowPassFilterSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.lowPassFilter),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Low Pass Filter'),
        subtitle: const Text(
          'Softens high frequencies like the original hardware',
        ),
        value: setting,
        onChanged: (value) => controller.lowPassFilter = value,
      ),
    );
  }
}
