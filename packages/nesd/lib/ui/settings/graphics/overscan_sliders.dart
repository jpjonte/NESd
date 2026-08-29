import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/settings/settings.dart';

class OverscanSliders extends StatelessWidget {
  const OverscanSliders({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverscanTopSlider(),
        OverscanBottomSlider(),
        OverscanLeftSlider(),
        OverscanRightSlider(),
      ],
    );
  }
}

class OverscanTopSlider extends StatelessWidget {
  const OverscanTopSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return _OverscanSlider(
      label: 'Overscan Top',
      value: (overscan) => overscan.top,
      update: (overscan, value) => overscan.copyWith(top: value),
      defaultValue: 8,
    );
  }
}

class OverscanBottomSlider extends StatelessWidget {
  const OverscanBottomSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return _OverscanSlider(
      label: 'Overscan Bottom',
      value: (overscan) => overscan.bottom,
      update: (overscan, value) => overscan.copyWith(bottom: value),
      defaultValue: 8,
    );
  }
}

class OverscanLeftSlider extends StatelessWidget {
  const OverscanLeftSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return _OverscanSlider(
      label: 'Overscan Left',
      value: (overscan) => overscan.left,
      update: (overscan, value) => overscan.copyWith(left: value),
      defaultValue: 0,
    );
  }
}

class OverscanRightSlider extends StatelessWidget {
  const OverscanRightSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return _OverscanSlider(
      label: 'Overscan Right',
      value: (overscan) => overscan.right,
      update: (overscan, value) => overscan.copyWith(right: value),
      defaultValue: 0,
    );
  }
}

class _OverscanSlider extends ConsumerWidget {
  const _OverscanSlider({
    required this.label,
    required this.value,
    required this.update,
    required this.defaultValue,
  });

  final String label;
  final int Function(Overscan) value;
  final Overscan Function(Overscan, int) update;
  final int defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overscan = ref.watch(
      settingsControllerProvider.select((s) => s.overscan),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final current = value(overscan);

    void set(int newValue) {
      controller.overscan = update(overscan, newValue);
    }

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => set(current - 1),
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => set(current + 1),
        ),
      },
      child: FocusOnHover(
        child: SliderSettingsTile(
          label: label,
          onTap: () => set(defaultValue),
          onChanged: (sliderValue) => set(sliderValue.round()),
          value: current.toDouble(),
          displayValue: '$current px',
          max: maxOverscan.toDouble(),
        ),
      ),
    );
  }
}
