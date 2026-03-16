import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class PixelAspectRatioSlider extends ConsumerWidget {
  const PixelAspectRatioSlider({this.enabled = true, super.key});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.customPixelAspectRatio),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) =>
              controller.customPixelAspectRatio = setting - 0.1,
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) =>
              controller.customPixelAspectRatio = setting + 0.1,
        ),
      },
      child: FocusOnHover(
        child: SliderSettingsTile(
          enabled: enabled,
          label: 'Custom Pixel Aspect Ratio',
          onTap: () => controller.customPixelAspectRatio = 1.0,
          onChanged: (value) =>
              controller.customPixelAspectRatio = value / 10.0,
          value: setting * 10.0,
          displayValue: setting.toStringAsFixed(1),
          min: 5.0, // 0.5
          max: 20.0, // 2.0
        ),
      ),
    );
  }
}
