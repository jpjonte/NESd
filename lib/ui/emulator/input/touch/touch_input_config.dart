import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/action.dart';

part 'touch_input_config.freezed.dart';
part 'touch_input_config.g.dart';

@Freezed(unionKey: 'type')
sealed class TouchInputConfig with _$TouchInputConfig {
  const TouchInputConfig._();

  const factory TouchInputConfig.rectangleButton({
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction action,
    required double x,
    required double y,
    @Default(60) double width,
    @Default(60) double height,
    @Default('') String label,
  }) = RectangleButtonConfig;

  const factory TouchInputConfig.circleButton({
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction action,
    required double x,
    required double y,
    @Default(75) double size,
    @Default('') String label,
  }) = CircleButtonConfig;

  const factory TouchInputConfig.joyStick({
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction upAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction downAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction leftAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction rightAction,
    required double x,
    required double y,
    @Default(150) double size,
    @Default(60) double innerSize,
    @Default(0.25) double deadZone,
  }) = JoyStickConfig;

  const factory TouchInputConfig.dPad({
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction upAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction downAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction leftAction,
    @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
    required NesAction rightAction,
    required double x,
    required double y,
    @Default(150) double size,
    @Default(0.25) double deadZone,
  }) = DPadConfig;

  factory TouchInputConfig.fromJson(Map<String, dynamic> json) =>
      _$TouchInputConfigFromJson(json);
}

const defaultNarrowConfig = [
  DPadConfig(
    x: -0.8,
    y: 0.5,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  CircleButtonConfig(
    x: 0.9,
    y: 0.5,
    action: controller1A,
    label: 'A',
  ),
  CircleButtonConfig(
    x: 0.35,
    y: 0.5,
    action: controller1B,
    label: 'B',
  ),
  RectangleButtonConfig(
    height: 40,
    x: -0.2,
    y: 0.1,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 40,
    x: 0.2,
    y: 0.1,
    action: controller1Start,
    label: 'Start',
  ),
];

const defaultWideConfig = [
  JoyStickConfig(
    x: -0.9,
    y: 0.0,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  CircleButtonConfig(
    x: 0.92,
    y: 0.0,
    action: controller1A,
    label: 'A',
  ),
  CircleButtonConfig(
    x: 0.67,
    y: 0.0,
    action: controller1B,
    label: 'B',
  ),
  RectangleButtonConfig(
    height: 40,
    x: -0.6,
    y: 0.9,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 40,
    x: 0.6,
    y: 0.9,
    action: controller1Start,
    label: 'Start',
  ),
];
