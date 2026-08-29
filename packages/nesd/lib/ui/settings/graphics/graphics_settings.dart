import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/features.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/graphics/border_switch.dart';
import 'package:nesd/ui/settings/graphics/crt_filter_sliders.dart';
import 'package:nesd/ui/settings/graphics/overscan_sliders.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_dropdown.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_slider.dart';
import 'package:nesd/ui/settings/graphics/renderer_selector.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/graphics/video_filter_switches.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class GraphicsSettings extends ConsumerWidget {
  const GraphicsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixelAspectRatio = ref.watch(
      settingsControllerProvider.select((s) => s.pixelAspectRatio),
    );
    final videoFilters = ref.watch(
      settingsControllerProvider.select((s) => s.videoFilters),
    );

    return SettingsTab(
      index: 1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Features.gpuRenderer) const RendererSelector(),
            const BorderSwitch(),
            const ScalingDropdown(),
            const PixelAspectRatioDropdown(),
            PixelAspectRatioSlider(
              enabled: pixelAspectRatio == PixelAspectRatio.custom,
            ),
            const OverscanSliders(),
            if (Features.videoFilters) ...[
              const SmoothingFilterSwitch(),
              const CrtFilterSwitch(),
              if (videoFilters.contains(VideoFilter.crt)) ...[
                const ScanlineIntensitySlider(),
                const MaskStrengthSlider(),
                const CurvatureSlider(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
