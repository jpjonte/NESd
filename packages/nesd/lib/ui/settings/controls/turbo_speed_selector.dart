import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
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

    const values = TurboSpeed.values;
    final index = values.indexOf(setting);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) =>
              controller.turboSpeed = index > 0 ? values[index - 1] : setting,
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => controller.turboSpeed =
              index < values.length - 1 ? values[index + 1] : setting,
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Turbo Speed'),
          adaptive: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: SegmentedButton<TurboSpeed>(
                onSelectionChanged: (value) =>
                    controller.turboSpeed = value.first,
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
