import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/settings/graphics/border_switch.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_dropdown.dart';
import 'package:nesd/ui/settings/graphics/pixel_aspect_ratio_slider.dart';
import 'package:nesd/ui/settings/graphics/renderer_selector.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class GraphicsSettings extends ConsumerWidget {
  const GraphicsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixelAspectRatio = ref.watch(
      settingsControllerProvider.select((s) => s.pixelAspectRatio),
    );

    return SettingsTab(
      index: 1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RendererSelector(),
            const BorderSwitch(),
            const ScalingDropdown(),
            const PixelAspectRatioDropdown(),
            PixelAspectRatioSlider(
              enabled: pixelAspectRatio == PixelAspectRatio.custom,
            ),
          ],
        ),
      ),
    );
  }
}
