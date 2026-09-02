import 'package:flutter/material.dart';
import 'package:nesd/ui/common/settings_section_header.dart';
import 'package:nesd/ui/settings/audio/low_pass_filter_switch.dart';
import 'package:nesd/ui/settings/audio/mixer_sliders.dart';
import 'package:nesd/ui/settings/audio/swap_duty_cycles_switch.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class AudioSettings extends StatelessWidget {
  const AudioSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsTab(
      index: 2,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SettingsSectionHeader(title: 'Output'),
            VolumeSlider(),
            LowPassFilterSwitch(),
            SwapDutyCyclesSwitch(),
            SettingsSectionHeader(title: 'Mixer'),
            MixerSliders(),
          ],
        ),
      ),
    );
  }
}
