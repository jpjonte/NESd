import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/settings/settings.dart';

class ScanlineIntensitySlider extends ConsumerWidget {
  const ScanlineIntensitySlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CrtSlider(
      label: 'Scanline Intensity',
      value: (crt) => crt.scanlineIntensity,
      update: (crt, value) => crt.copyWith(scanlineIntensity: value),
      max: 1,
      defaultValue: 0.35,
    );
  }
}

class MaskStrengthSlider extends ConsumerWidget {
  const MaskStrengthSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CrtSlider(
      label: 'Mask Strength',
      value: (crt) => crt.maskStrength,
      update: (crt, value) => crt.copyWith(maskStrength: value),
      max: 1,
      defaultValue: 0.25,
    );
  }
}

class CurvatureSlider extends ConsumerWidget {
  const CurvatureSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CrtSlider(
      label: 'Curvature',
      value: (crt) => crt.curvature,
      update: (crt, value) => crt.copyWith(curvature: value),
      max: 0.25,
      defaultValue: 0,
    );
  }
}

class _CrtSlider extends ConsumerWidget {
  const _CrtSlider({
    required this.label,
    required this.value,
    required this.update,
    required this.max,
    required this.defaultValue,
  });

  final String label;
  final double Function(CrtFilterSettings) value;
  final CrtFilterSettings Function(CrtFilterSettings, double) update;
  final double max;
  final double defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crt = ref.watch(
      settingsControllerProvider.select((s) => s.crtFilter),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final current = value(crt);

    void set(double newValue) {
      controller.crtFilter = update(crt, newValue.clamp(0.0, max));
    }

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => set(current - 0.05),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => set(current + 0.05),
        ),
      },
      child: FocusOnHover(
        child: SliderSettingsTile(
          label: label,
          onTap: () => set(defaultValue),
          onChanged: (sliderValue) => set(sliderValue / 100),
          value: current * 100,
          displayValue: '${(current * 100).round()}%',
          max: max * 100,
        ),
      ),
    );
  }
}
