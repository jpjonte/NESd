import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/input/touch/circle_button.dart';
import 'package:nesd/ui/emulator/input/touch/d_pad.dart';
import 'package:nesd/ui/emulator/input/touch/joy_stick.dart';
import 'package:nesd/ui/emulator/input/touch/rectangle_button.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/settings.dart';

class TouchControls extends ConsumerWidget {
  const TouchControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final narrowConfig = ref.watch(
      settingsControllerProvider
          .select((settings) => settings.narrowTouchInputConfig),
    );

    final wideConfig = ref.watch(
      settingsControllerProvider
          .select((settings) => settings.wideTouchInputConfig),
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < constraints.maxHeight;

        final config = narrow ? narrowConfig : wideConfig;

        return Stack(
          children: [
            for (final item in config)
              switch (item) {
                RectangleButtonConfig() => RectangleButton(config: item),
                CircleButtonConfig() => CircleButton(config: item),
                DPadConfig() => DPad(config: item),
                JoyStickConfig() => JoyStick(config: item),
              },
          ],
        );
      },
    );
  }
}
