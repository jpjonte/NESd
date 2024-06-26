import 'package:flutter/material.dart';
import 'package:nes/ui/settings/audio/volume_slider.dart';

class AudioSettings extends StatelessWidget {
  const AudioSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        VolumeSlider(),
      ],
    );
  }
}
