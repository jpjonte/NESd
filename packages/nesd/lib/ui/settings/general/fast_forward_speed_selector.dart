import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
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

    const values = FastForwardSpeed.values;
    final index = values.indexOf(setting);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => controller.fastForwardSpeed = index > 0
              ? values[index - 1]
              : setting,
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => controller.fastForwardSpeed =
              index < values.length - 1 ? values[index + 1] : setting,
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Fast Forward Speed'),
          adaptive: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: SegmentedButton<FastForwardSpeed>(
                onSelectionChanged: (value) =>
                    controller.fastForwardSpeed = value.first,
                segments: [
                  for (final speed in values)
                    ButtonSegment(
                      icon: const SizedBox(width: 18, height: 18),
                      label: Center(
                        child: Text(
                          speed.label,
                          style: const TextStyle(
                            fontVariations: [FontVariation.weight(700)],
                          ),
                        ),
                      ),
                      value: speed,
                    ),
                ],
                selected: {setting},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
