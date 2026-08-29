import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class SwapDutyCyclesSwitch extends ConsumerWidget {
  const SwapDutyCyclesSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.swapDutyCycles),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Swap Duty Cycles'),
        subtitle: const Text(
          'Swaps the pulse channels’ duty cycles, like on many Famiclones',
        ),
        value: setting,
        onChanged: (value) => controller.swapDutyCycles = value,
      ),
    );
  }
}
