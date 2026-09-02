import 'package:nesd/nes/apu/mixer_settings.dart';

@pragma('vm:prefer-inline')
double mixSample({
  required int pulse1,
  required int pulse2,
  required int triangle,
  required int noise,
  required int dmc,
  required double expansion,
  required MixerSettings mixer,
}) {
  final pulseIndex = pulse1 * mixer.pulse1 + pulse2 * mixer.pulse2;

  final tndIndex =
      3 * triangle * mixer.triangle + 2 * noise * mixer.noise + dmc * mixer.dmc;

  return pulseMix(pulseIndex) + tndMix(tndIndex) + expansion;
}

@pragma('vm:prefer-inline')
double pulseMix(double index) => 95.52 / (8128.0 / index + 100);

@pragma('vm:prefer-inline')
double tndMix(double index) => 163.67 / (24329.0 / index + 100);
