import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class HueSlider extends ConsumerWidget {
  const HueSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _NtscSlider(
    label: 'Hue',
    value: (s) => s.hue,
    update: (s, value) => s.copyWith(hue: value),
    min: -6,
    max: 6,
    defaultValue: 0,
  );
}

class SaturationSlider extends ConsumerWidget {
  const SaturationSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _NtscSlider(
    label: 'Saturation',
    value: (s) => s.saturation,
    update: (s, value) => s.copyWith(saturation: value),
    min: 0,
    max: 2,
    defaultValue: 1,
  );
}

class ContrastSlider extends ConsumerWidget {
  const ContrastSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _NtscSlider(
    label: 'Contrast',
    value: (s) => s.contrast,
    update: (s, value) => s.copyWith(contrast: value),
    min: 0,
    max: 2,
    defaultValue: 1,
  );
}

class BrightnessSlider extends ConsumerWidget {
  const BrightnessSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _NtscSlider(
    label: 'Brightness',
    value: (s) => s.brightness,
    update: (s, value) => s.copyWith(brightness: value),
    min: 0,
    max: 2,
    defaultValue: 1,
  );
}

class GammaSlider extends ConsumerWidget {
  const GammaSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _NtscSlider(
    label: 'Gamma',
    value: (s) => s.gamma,
    update: (s, value) => s.copyWith(gamma: value),
    min: 1,
    max: 3,
    defaultValue: 1.8,
  );
}

class _NtscSlider extends ConsumerWidget {
  const _NtscSlider({
    required this.label,
    required this.value,
    required this.update,
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  final String label;
  final double Function(NtscPaletteSettings) value;
  final NtscPaletteSettings Function(NtscPaletteSettings, double) update;
  final double min;
  final double max;
  final double defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      settingsControllerProvider.select((s) => s.ntscPalette),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final current = value(settings);

    void set(double newValue) {
      controller.ntscPalette = update(settings, newValue.clamp(min, max));
    }

    final step = (max - min) / 20;

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => set(current - step),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => set(current + step),
        ),
      },
      child: FocusOnHover(
        child: SliderSettingsTile(
          label: label,
          onTap: () => set(defaultValue),
          onChanged: set,
          value: current,
          displayValue: current.toStringAsFixed(2),
          min: min,
          max: max,
        ),
      ),
    );
  }
}
