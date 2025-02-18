import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.volume),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => controller.volume = setting - 0.05,
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => controller.volume = setting + 0.05,
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Volume'),
          onTap: () => controller.volume = 0.5,
          child: LayoutBuilder(
            builder:
                (_, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  child: Slider(
                    value: setting,
                    onChanged: (value) => controller.volume = value,
                    label: 'Volume',
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
