import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';

class AudioToolWidget extends StatelessWidget {
  const AudioToolWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [VolumeSlider(), LowPassFilterSwitch(), SwapDutyCyclesSwitch()],
    );
  }
}
