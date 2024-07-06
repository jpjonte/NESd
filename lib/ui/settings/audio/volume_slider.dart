import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/common/focus_on_hover.dart';
import 'package:nes/ui/emulator/input/intents.dart';
import 'package:nes/ui/settings/settings.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.volume));
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
        child: ListTile(
          title: const Text('Volume'),
          onTap: () => controller.volume = 0.5,
          trailing: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ExcludeFocusTraversal(
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
