import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/touch/circle_button.dart';
import 'package:nesd/ui/emulator/input/touch/d_pad.dart';
import 'package:nesd/ui/emulator/input/touch/joy_stick.dart';
import 'package:nesd/ui/emulator/input/touch/rectangle_button.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/settings/settings.dart';

class TouchControlsBuilder extends ConsumerWidget {
  const TouchControlsBuilder({this.edit = false, super.key});

  final bool edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portraitConfig = ref.watch(
      settingsControllerProvider
          .select((settings) => settings.narrowTouchInputConfig),
    );

    final landscapeConfig = ref.watch(
      settingsControllerProvider
          .select((settings) => settings.wideTouchInputConfig),
    );

    return TouchControls(
      portraitConfig: portraitConfig,
      landscapeConfig: landscapeConfig,
    );
  }
}

class TouchControls extends HookConsumerWidget {
  const TouchControls({
    required this.portraitConfig,
    required this.landscapeConfig,
    super.key,
  });

  final List<TouchInputConfig> portraitConfig;
  final List<TouchInputConfig> landscapeConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (_, orientation) {
        final config = orientation == Orientation.portrait
            ? portraitConfig
            : landscapeConfig;

        return LayoutBuilder(
          builder: (context, constraints) {
            return TouchArea(
              constraints: constraints,
              child: Stack(
                children: [
                  for (final item in config) TouchControl(config: item),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class TouchControl extends StatelessWidget {
  const TouchControl({
    required this.config,
  });

  final TouchInputConfig config;

  @override
  Widget build(BuildContext context) {
    return switch (config) {
      final RectangleButtonConfig config => RectangleButton(config: config),
      final CircleButtonConfig config => CircleButton(config: config),
      final DPadConfig config => DPad(config: config),
      final JoyStickConfig config => JoyStick(config: config),
    };
  }
}

class TouchArea extends InheritedWidget {
  const TouchArea({
    required this.constraints,
    required super.child,
    super.key,
  });

  final BoxConstraints constraints;

  static TouchArea? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TouchArea>();
  }

  static TouchArea of(BuildContext context) {
    final result = maybeOf(context);

    assert(result != null, 'No TouchArea found in context');

    return result!;
  }

  Size get size => constraints.biggest;

  Size get halfSize => Size(size.width / 2, size.height / 2);

  Offset get center => Offset(size.width / 2, size.height / 2);

  @override
  bool updateShouldNotify(TouchArea oldWidget) =>
      constraints != oldWidget.constraints;
}
