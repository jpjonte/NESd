import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';

part 'touch_input_config.freezed.dart';
part 'touch_input_config.g.dart';

enum TouchInputType {
  rectangleButton(),
  circleButton(),
  joyStick(),
  dPad();

  static TouchInputType forTouchInputConfig(TouchInputConfig config) {
    return switch (config) {
      RectangleButtonConfig() => rectangleButton,
      CircleButtonConfig() => circleButton,
      JoyStickConfig() => joyStick,
      DPadConfig() => dPad,
    };
  }
}

@Freezed(unionKey: 'type')
sealed class TouchInputConfig with _$TouchInputConfig {
  const TouchInputConfig._();

  const factory TouchInputConfig.rectangleButton({
    required double x,
    required double y,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? action,
    @Default(60) double width,
    @Default(60) double height,
    @Default('') String label,
  }) = RectangleButtonConfig;

  const factory TouchInputConfig.circleButton({
    required double x,
    required double y,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? action,
    @Default(75) double size,
    @Default('') String label,
  }) = CircleButtonConfig;

  const factory TouchInputConfig.joyStick({
    required double x,
    required double y,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? upAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? downAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? leftAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? rightAction,
    @Default(150) double size,
    @Default(60) double innerSize,
    @Default(0.25) double deadZone,
  }) = JoyStickConfig;

  const factory TouchInputConfig.dPad({
    required double x,
    required double y,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? upAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? downAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? leftAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? rightAction,
    @Default(150) double size,
    @Default(0.25) double deadZone,
  }) = DPadConfig;

  Offset get position => Offset(x, y);

  Offset denormalizedPosition(Size viewport) {
    final center = viewport.center(Offset.zero);
    final relative = Offset(x * center.dx, y * center.dy);

    return center + relative;
  }

  Offset center(Size viewport) {
    final center = viewport.center(Offset.zero);
    final relative = Offset(x * center.dx, y * center.dy);

    return center + relative;
  }

  Rect boundingBox(Size viewport) => Rect.fromCenter(
        center: center(viewport),
        width: width,
        height: height,
      );

  double get height => switch (this) {
        RectangleButtonConfig(height: final height) => height,
        CircleButtonConfig(size: final size) => size,
        JoyStickConfig(size: final size) => size,
        DPadConfig(size: final size) => size,
      };

  double get width => switch (this) {
        RectangleButtonConfig(width: final width) => width,
        CircleButtonConfig(size: final size) => size,
        JoyStickConfig(size: final size) => size,
        DPadConfig(size: final size) => size,
      };

  factory TouchInputConfig.fromJson(Map<String, dynamic> json) =>
      _$TouchInputConfigFromJson(json);
}

const defaultPortraitConfig = [
  DPadConfig(
    x: -0.55,
    y: 0.4,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  CircleButtonConfig(
    x: 0.7,
    y: 0.4,
    action: controller1A,
    label: 'A',
  ),
  CircleButtonConfig(
    x: 0.2,
    y: 0.4,
    action: controller1B,
    label: 'B',
  ),
  RectangleButtonConfig(
    height: 40,
    x: -0.25,
    y: 0.0,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 40,
    x: 0.25,
    y: 0.0,
    action: controller1Start,
    label: 'Start',
  ),
];

const defaultLandscapeConfig = [
  JoyStickConfig(
    x: -0.7,
    y: -0.1,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  CircleButtonConfig(
    x: 0.85,
    y: -0.1,
    action: controller1A,
    label: 'A',
  ),
  CircleButtonConfig(
    x: 0.6,
    y: -0.1,
    action: controller1B,
    label: 'B',
  ),
  RectangleButtonConfig(
    height: 40,
    x: -0.6,
    y: 0.75,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 40,
    x: 0.6,
    y: 0.75,
    action: controller1Start,
    label: 'Start',
  ),
];
