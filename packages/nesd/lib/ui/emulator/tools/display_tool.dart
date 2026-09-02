import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/graphics/border_switch.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/ntsc_palette_sliders.dart';
import 'package:nesd/ui/settings/graphics/overscan_sliders.dart';
import 'package:nesd/ui/settings/graphics/palette_dropdown.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_dropdown.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_slider.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/graphics/video_filter_switches.dart';
import 'package:nesd/ui/settings/settings.dart';

class DisplayToolWidget extends ConsumerWidget {
  const DisplayToolWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoFilters = ref.watch(
      settingsControllerProvider.select((s) => s.videoFilters),
    );
    final pixelAspectRatio = ref.watch(
      settingsControllerProvider.select((s) => s.pixelAspectRatio),
    );
    final paletteId = ref.watch(
      settingsControllerProvider.select((s) => s.paletteId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const UpscalingFilterSwitch(),
        const SmoothingFilterSwitch(),
        const CrtFilterSwitch(),
        if (videoFilters.contains(VideoFilter.crt)) ...[
          const ScanlineIntensitySlider(),
          const MaskStrengthSlider(),
          const CurvatureSlider(),
        ],
        const PaletteDropdown(expand: true),
        if (paletteId == NesPaletteId.generated) ...[
          const HueSlider(),
          const SaturationSlider(),
          const ContrastSlider(),
          const BrightnessSlider(),
          const GammaSlider(),
        ],
        const ScalingDropdown(expand: true),
        const PixelAspectRatioDropdown(expand: true),
        PixelAspectRatioSlider(
          enabled: pixelAspectRatio == PixelAspectRatio.custom,
        ),
        const OverscanSliders(),
        const BorderSwitch(),
      ],
    );
  }
}
