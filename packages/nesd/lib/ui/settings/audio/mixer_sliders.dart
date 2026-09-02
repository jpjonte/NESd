import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class MixerSliders extends StatelessWidget {
  const MixerSliders({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Pulse1GainSlider(),
        Pulse2GainSlider(),
        TriangleGainSlider(),
        NoiseGainSlider(),
        DmcGainSlider(),
        Mmc5GainSlider(),
        Namco163GainSlider(),
      ],
    );
  }
}

class Pulse1GainSlider extends StatelessWidget {
  const Pulse1GainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'Pulse 1',
    value: (mixer) => mixer.pulse1,
    update: (mixer, value) => mixer.copyWith(pulse1: value),
  );
}

class Pulse2GainSlider extends StatelessWidget {
  const Pulse2GainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'Pulse 2',
    value: (mixer) => mixer.pulse2,
    update: (mixer, value) => mixer.copyWith(pulse2: value),
  );
}

class TriangleGainSlider extends StatelessWidget {
  const TriangleGainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'Triangle',
    value: (mixer) => mixer.triangle,
    update: (mixer, value) => mixer.copyWith(triangle: value),
  );
}

class NoiseGainSlider extends StatelessWidget {
  const NoiseGainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'Noise',
    value: (mixer) => mixer.noise,
    update: (mixer, value) => mixer.copyWith(noise: value),
  );
}

class DmcGainSlider extends StatelessWidget {
  const DmcGainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'DMC',
    value: (mixer) => mixer.dmc,
    update: (mixer, value) => mixer.copyWith(dmc: value),
  );
}

class Mmc5GainSlider extends StatelessWidget {
  const Mmc5GainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'MMC5',
    value: (mixer) => mixer.mmc5,
    update: (mixer, value) => mixer.copyWith(mmc5: value),
  );
}

class Namco163GainSlider extends StatelessWidget {
  const Namco163GainSlider({super.key});

  @override
  Widget build(BuildContext context) => _MixerSlider(
    label: 'Namco 163',
    value: (mixer) => mixer.namco163,
    update: (mixer, value) => mixer.copyWith(namco163: value),
  );
}

class _MixerSlider extends ConsumerWidget {
  const _MixerSlider({
    required this.label,
    required this.value,
    required this.update,
  });

  final String label;
  final double Function(MixerSettings) value;
  final MixerSettings Function(MixerSettings, double) update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(settingsControllerProvider.select((s) => s.mixer));
    final controller = ref.read(settingsControllerProvider.notifier);
    final current = value(mixer);

    void set(double newValue) {
      controller.mixer = update(mixer, newValue);
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
          onTap: () => set(1),
          onChanged: set,
          value: current,
          displayValue: (current * 100).toStringAsFixed(0),
        ),
      ),
    );
  }
}
