import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/audio/volume_slider.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class AudioSettings extends StatelessWidget {
  const AudioSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTab(
      index: 2,
      child: ListView(
        children: const [
          VolumeSlider(),
        ],
      ),
    );
  }
}
