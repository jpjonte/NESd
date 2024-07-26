// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'touch_input_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TouchInputConfig _$TouchInputConfigFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'rectangleButton':
      return RectangleButtonConfig.fromJson(json);
    case 'circleButton':
      return CircleButtonConfig.fromJson(json);
    case 'joyStick':
      return JoyStickConfig.fromJson(json);
    case 'dPad':
      return DPadConfig.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'type', 'TouchInputConfig',
          'Invalid union type "${json['type']}"!');
  }
}

/// @nodoc
mixin _$TouchInputConfig {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)
        rectangleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)
        circleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)
        joyStick,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)
        dPad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RectangleButtonConfig value) rectangleButton,
    required TResult Function(CircleButtonConfig value) circleButton,
    required TResult Function(JoyStickConfig value) joyStick,
    required TResult Function(DPadConfig value) dPad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RectangleButtonConfig value)? rectangleButton,
    TResult? Function(CircleButtonConfig value)? circleButton,
    TResult? Function(JoyStickConfig value)? joyStick,
    TResult? Function(DPadConfig value)? dPad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RectangleButtonConfig value)? rectangleButton,
    TResult Function(CircleButtonConfig value)? circleButton,
    TResult Function(JoyStickConfig value)? joyStick,
    TResult Function(DPadConfig value)? dPad,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TouchInputConfigCopyWith<TouchInputConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TouchInputConfigCopyWith<$Res> {
  factory $TouchInputConfigCopyWith(
          TouchInputConfig value, $Res Function(TouchInputConfig) then) =
      _$TouchInputConfigCopyWithImpl<$Res, TouchInputConfig>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$TouchInputConfigCopyWithImpl<$Res, $Val extends TouchInputConfig>
    implements $TouchInputConfigCopyWith<$Res> {
  _$TouchInputConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RectangleButtonConfigImplCopyWith<$Res>
    implements $TouchInputConfigCopyWith<$Res> {
  factory _$$RectangleButtonConfigImplCopyWith(
          _$RectangleButtonConfigImpl value,
          $Res Function(_$RectangleButtonConfigImpl) then) =
      __$$RectangleButtonConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction action,
      double x,
      double y,
      double width,
      double height,
      String label});
}

/// @nodoc
class __$$RectangleButtonConfigImplCopyWithImpl<$Res>
    extends _$TouchInputConfigCopyWithImpl<$Res, _$RectangleButtonConfigImpl>
    implements _$$RectangleButtonConfigImplCopyWith<$Res> {
  __$$RectangleButtonConfigImplCopyWithImpl(_$RectangleButtonConfigImpl _value,
      $Res Function(_$RectangleButtonConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? label = null,
  }) {
    return _then(_$RectangleButtonConfigImpl(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as NesAction,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RectangleButtonConfigImpl extends RectangleButtonConfig {
  const _$RectangleButtonConfigImpl(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.action,
      required this.x,
      required this.y,
      this.width = 60,
      this.height = 60,
      this.label = '',
      final String? $type})
      : $type = $type ?? 'rectangleButton',
        super._();

  factory _$RectangleButtonConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$RectangleButtonConfigImplFromJson(json);

  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction action;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final double width;
  @override
  @JsonKey()
  final double height;
  @override
  @JsonKey()
  final String label;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'TouchInputConfig.rectangleButton(action: $action, x: $x, y: $y, width: $width, height: $height, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RectangleButtonConfigImpl &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, action, x, y, width, height, label);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RectangleButtonConfigImplCopyWith<_$RectangleButtonConfigImpl>
      get copyWith => __$$RectangleButtonConfigImplCopyWithImpl<
          _$RectangleButtonConfigImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)
        rectangleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)
        circleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)
        joyStick,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)
        dPad,
  }) {
    return rectangleButton(action, x, y, width, height, label);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
  }) {
    return rectangleButton?.call(action, x, y, width, height, label);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
    required TResult orElse(),
  }) {
    if (rectangleButton != null) {
      return rectangleButton(action, x, y, width, height, label);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RectangleButtonConfig value) rectangleButton,
    required TResult Function(CircleButtonConfig value) circleButton,
    required TResult Function(JoyStickConfig value) joyStick,
    required TResult Function(DPadConfig value) dPad,
  }) {
    return rectangleButton(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RectangleButtonConfig value)? rectangleButton,
    TResult? Function(CircleButtonConfig value)? circleButton,
    TResult? Function(JoyStickConfig value)? joyStick,
    TResult? Function(DPadConfig value)? dPad,
  }) {
    return rectangleButton?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RectangleButtonConfig value)? rectangleButton,
    TResult Function(CircleButtonConfig value)? circleButton,
    TResult Function(JoyStickConfig value)? joyStick,
    TResult Function(DPadConfig value)? dPad,
    required TResult orElse(),
  }) {
    if (rectangleButton != null) {
      return rectangleButton(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RectangleButtonConfigImplToJson(
      this,
    );
  }
}

abstract class RectangleButtonConfig extends TouchInputConfig {
  const factory RectangleButtonConfig(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction action,
      required final double x,
      required final double y,
      final double width,
      final double height,
      final String label}) = _$RectangleButtonConfigImpl;
  const RectangleButtonConfig._() : super._();

  factory RectangleButtonConfig.fromJson(Map<String, dynamic> json) =
      _$RectangleButtonConfigImpl.fromJson;

  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get action;
  @override
  double get x;
  @override
  double get y;
  double get width;
  double get height;
  String get label;
  @override
  @JsonKey(ignore: true)
  _$$RectangleButtonConfigImplCopyWith<_$RectangleButtonConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CircleButtonConfigImplCopyWith<$Res>
    implements $TouchInputConfigCopyWith<$Res> {
  factory _$$CircleButtonConfigImplCopyWith(_$CircleButtonConfigImpl value,
          $Res Function(_$CircleButtonConfigImpl) then) =
      __$$CircleButtonConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction action,
      double x,
      double y,
      double size,
      String label});
}

/// @nodoc
class __$$CircleButtonConfigImplCopyWithImpl<$Res>
    extends _$TouchInputConfigCopyWithImpl<$Res, _$CircleButtonConfigImpl>
    implements _$$CircleButtonConfigImplCopyWith<$Res> {
  __$$CircleButtonConfigImplCopyWithImpl(_$CircleButtonConfigImpl _value,
      $Res Function(_$CircleButtonConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? x = null,
    Object? y = null,
    Object? size = null,
    Object? label = null,
  }) {
    return _then(_$CircleButtonConfigImpl(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as NesAction,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as double,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CircleButtonConfigImpl extends CircleButtonConfig {
  const _$CircleButtonConfigImpl(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.action,
      required this.x,
      required this.y,
      this.size = 75,
      this.label = '',
      final String? $type})
      : $type = $type ?? 'circleButton',
        super._();

  factory _$CircleButtonConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$CircleButtonConfigImplFromJson(json);

  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction action;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final double size;
  @override
  @JsonKey()
  final String label;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'TouchInputConfig.circleButton(action: $action, x: $x, y: $y, size: $size, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CircleButtonConfigImpl &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, action, x, y, size, label);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CircleButtonConfigImplCopyWith<_$CircleButtonConfigImpl> get copyWith =>
      __$$CircleButtonConfigImplCopyWithImpl<_$CircleButtonConfigImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)
        rectangleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)
        circleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)
        joyStick,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)
        dPad,
  }) {
    return circleButton(action, x, y, size, label);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
  }) {
    return circleButton?.call(action, x, y, size, label);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
    required TResult orElse(),
  }) {
    if (circleButton != null) {
      return circleButton(action, x, y, size, label);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RectangleButtonConfig value) rectangleButton,
    required TResult Function(CircleButtonConfig value) circleButton,
    required TResult Function(JoyStickConfig value) joyStick,
    required TResult Function(DPadConfig value) dPad,
  }) {
    return circleButton(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RectangleButtonConfig value)? rectangleButton,
    TResult? Function(CircleButtonConfig value)? circleButton,
    TResult? Function(JoyStickConfig value)? joyStick,
    TResult? Function(DPadConfig value)? dPad,
  }) {
    return circleButton?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RectangleButtonConfig value)? rectangleButton,
    TResult Function(CircleButtonConfig value)? circleButton,
    TResult Function(JoyStickConfig value)? joyStick,
    TResult Function(DPadConfig value)? dPad,
    required TResult orElse(),
  }) {
    if (circleButton != null) {
      return circleButton(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CircleButtonConfigImplToJson(
      this,
    );
  }
}

abstract class CircleButtonConfig extends TouchInputConfig {
  const factory CircleButtonConfig(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction action,
      required final double x,
      required final double y,
      final double size,
      final String label}) = _$CircleButtonConfigImpl;
  const CircleButtonConfig._() : super._();

  factory CircleButtonConfig.fromJson(Map<String, dynamic> json) =
      _$CircleButtonConfigImpl.fromJson;

  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get action;
  @override
  double get x;
  @override
  double get y;
  double get size;
  String get label;
  @override
  @JsonKey(ignore: true)
  _$$CircleButtonConfigImplCopyWith<_$CircleButtonConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$JoyStickConfigImplCopyWith<$Res>
    implements $TouchInputConfigCopyWith<$Res> {
  factory _$$JoyStickConfigImplCopyWith(_$JoyStickConfigImpl value,
          $Res Function(_$JoyStickConfigImpl) then) =
      __$$JoyStickConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction rightAction,
      double x,
      double y,
      double size,
      double innerSize,
      double deadZone});
}

/// @nodoc
class __$$JoyStickConfigImplCopyWithImpl<$Res>
    extends _$TouchInputConfigCopyWithImpl<$Res, _$JoyStickConfigImpl>
    implements _$$JoyStickConfigImplCopyWith<$Res> {
  __$$JoyStickConfigImplCopyWithImpl(
      _$JoyStickConfigImpl _value, $Res Function(_$JoyStickConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? upAction = null,
    Object? downAction = null,
    Object? leftAction = null,
    Object? rightAction = null,
    Object? x = null,
    Object? y = null,
    Object? size = null,
    Object? innerSize = null,
    Object? deadZone = null,
  }) {
    return _then(_$JoyStickConfigImpl(
      upAction: null == upAction
          ? _value.upAction
          : upAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      downAction: null == downAction
          ? _value.downAction
          : downAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      leftAction: null == leftAction
          ? _value.leftAction
          : leftAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      rightAction: null == rightAction
          ? _value.rightAction
          : rightAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as double,
      innerSize: null == innerSize
          ? _value.innerSize
          : innerSize // ignore: cast_nullable_to_non_nullable
              as double,
      deadZone: null == deadZone
          ? _value.deadZone
          : deadZone // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JoyStickConfigImpl extends JoyStickConfig {
  const _$JoyStickConfigImpl(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.rightAction,
      required this.x,
      required this.y,
      this.size = 150,
      this.innerSize = 60,
      this.deadZone = 0.25,
      final String? $type})
      : $type = $type ?? 'joyStick',
        super._();

  factory _$JoyStickConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoyStickConfigImplFromJson(json);

  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction upAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction downAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction leftAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction rightAction;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final double size;
  @override
  @JsonKey()
  final double innerSize;
  @override
  @JsonKey()
  final double deadZone;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'TouchInputConfig.joyStick(upAction: $upAction, downAction: $downAction, leftAction: $leftAction, rightAction: $rightAction, x: $x, y: $y, size: $size, innerSize: $innerSize, deadZone: $deadZone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoyStickConfigImpl &&
            (identical(other.upAction, upAction) ||
                other.upAction == upAction) &&
            (identical(other.downAction, downAction) ||
                other.downAction == downAction) &&
            (identical(other.leftAction, leftAction) ||
                other.leftAction == leftAction) &&
            (identical(other.rightAction, rightAction) ||
                other.rightAction == rightAction) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.innerSize, innerSize) ||
                other.innerSize == innerSize) &&
            (identical(other.deadZone, deadZone) ||
                other.deadZone == deadZone));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, upAction, downAction, leftAction,
      rightAction, x, y, size, innerSize, deadZone);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JoyStickConfigImplCopyWith<_$JoyStickConfigImpl> get copyWith =>
      __$$JoyStickConfigImplCopyWithImpl<_$JoyStickConfigImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)
        rectangleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)
        circleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)
        joyStick,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)
        dPad,
  }) {
    return joyStick(upAction, downAction, leftAction, rightAction, x, y, size,
        innerSize, deadZone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
  }) {
    return joyStick?.call(upAction, downAction, leftAction, rightAction, x, y,
        size, innerSize, deadZone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
    required TResult orElse(),
  }) {
    if (joyStick != null) {
      return joyStick(upAction, downAction, leftAction, rightAction, x, y, size,
          innerSize, deadZone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RectangleButtonConfig value) rectangleButton,
    required TResult Function(CircleButtonConfig value) circleButton,
    required TResult Function(JoyStickConfig value) joyStick,
    required TResult Function(DPadConfig value) dPad,
  }) {
    return joyStick(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RectangleButtonConfig value)? rectangleButton,
    TResult? Function(CircleButtonConfig value)? circleButton,
    TResult? Function(JoyStickConfig value)? joyStick,
    TResult? Function(DPadConfig value)? dPad,
  }) {
    return joyStick?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RectangleButtonConfig value)? rectangleButton,
    TResult Function(CircleButtonConfig value)? circleButton,
    TResult Function(JoyStickConfig value)? joyStick,
    TResult Function(DPadConfig value)? dPad,
    required TResult orElse(),
  }) {
    if (joyStick != null) {
      return joyStick(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$JoyStickConfigImplToJson(
      this,
    );
  }
}

abstract class JoyStickConfig extends TouchInputConfig {
  const factory JoyStickConfig(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction rightAction,
      required final double x,
      required final double y,
      final double size,
      final double innerSize,
      final double deadZone}) = _$JoyStickConfigImpl;
  const JoyStickConfig._() : super._();

  factory JoyStickConfig.fromJson(Map<String, dynamic> json) =
      _$JoyStickConfigImpl.fromJson;

  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get upAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get downAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get leftAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get rightAction;
  @override
  double get x;
  @override
  double get y;
  double get size;
  double get innerSize;
  double get deadZone;
  @override
  @JsonKey(ignore: true)
  _$$JoyStickConfigImplCopyWith<_$JoyStickConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DPadConfigImplCopyWith<$Res>
    implements $TouchInputConfigCopyWith<$Res> {
  factory _$$DPadConfigImplCopyWith(
          _$DPadConfigImpl value, $Res Function(_$DPadConfigImpl) then) =
      __$$DPadConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      NesAction rightAction,
      double x,
      double y,
      double size,
      double deadZone});
}

/// @nodoc
class __$$DPadConfigImplCopyWithImpl<$Res>
    extends _$TouchInputConfigCopyWithImpl<$Res, _$DPadConfigImpl>
    implements _$$DPadConfigImplCopyWith<$Res> {
  __$$DPadConfigImplCopyWithImpl(
      _$DPadConfigImpl _value, $Res Function(_$DPadConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? upAction = null,
    Object? downAction = null,
    Object? leftAction = null,
    Object? rightAction = null,
    Object? x = null,
    Object? y = null,
    Object? size = null,
    Object? deadZone = null,
  }) {
    return _then(_$DPadConfigImpl(
      upAction: null == upAction
          ? _value.upAction
          : upAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      downAction: null == downAction
          ? _value.downAction
          : downAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      leftAction: null == leftAction
          ? _value.leftAction
          : leftAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      rightAction: null == rightAction
          ? _value.rightAction
          : rightAction // ignore: cast_nullable_to_non_nullable
              as NesAction,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as double,
      deadZone: null == deadZone
          ? _value.deadZone
          : deadZone // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DPadConfigImpl extends DPadConfig {
  const _$DPadConfigImpl(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required this.rightAction,
      required this.x,
      required this.y,
      this.size = 150,
      this.deadZone = 0.25,
      final String? $type})
      : $type = $type ?? 'dPad',
        super._();

  factory _$DPadConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$DPadConfigImplFromJson(json);

  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction upAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction downAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction leftAction;
  @override
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  final NesAction rightAction;
  @override
  final double x;
  @override
  final double y;
  @override
  @JsonKey()
  final double size;
  @override
  @JsonKey()
  final double deadZone;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'TouchInputConfig.dPad(upAction: $upAction, downAction: $downAction, leftAction: $leftAction, rightAction: $rightAction, x: $x, y: $y, size: $size, deadZone: $deadZone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DPadConfigImpl &&
            (identical(other.upAction, upAction) ||
                other.upAction == upAction) &&
            (identical(other.downAction, downAction) ||
                other.downAction == downAction) &&
            (identical(other.leftAction, leftAction) ||
                other.leftAction == leftAction) &&
            (identical(other.rightAction, rightAction) ||
                other.rightAction == rightAction) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.deadZone, deadZone) ||
                other.deadZone == deadZone));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, upAction, downAction, leftAction,
      rightAction, x, y, size, deadZone);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DPadConfigImplCopyWith<_$DPadConfigImpl> get copyWith =>
      __$$DPadConfigImplCopyWithImpl<_$DPadConfigImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)
        rectangleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)
        circleButton,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)
        joyStick,
    required TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)
        dPad,
  }) {
    return dPad(
        upAction, downAction, leftAction, rightAction, x, y, size, deadZone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult? Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
  }) {
    return dPad?.call(
        upAction, downAction, leftAction, rightAction, x, y, size, deadZone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double width,
            double height,
            String label)?
        rectangleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction action,
            double x,
            double y,
            double size,
            String label)?
        circleButton,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double innerSize,
            double deadZone)?
        joyStick,
    TResult Function(
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction upAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction downAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction leftAction,
            @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
            NesAction rightAction,
            double x,
            double y,
            double size,
            double deadZone)?
        dPad,
    required TResult orElse(),
  }) {
    if (dPad != null) {
      return dPad(
          upAction, downAction, leftAction, rightAction, x, y, size, deadZone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RectangleButtonConfig value) rectangleButton,
    required TResult Function(CircleButtonConfig value) circleButton,
    required TResult Function(JoyStickConfig value) joyStick,
    required TResult Function(DPadConfig value) dPad,
  }) {
    return dPad(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RectangleButtonConfig value)? rectangleButton,
    TResult? Function(CircleButtonConfig value)? circleButton,
    TResult? Function(JoyStickConfig value)? joyStick,
    TResult? Function(DPadConfig value)? dPad,
  }) {
    return dPad?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RectangleButtonConfig value)? rectangleButton,
    TResult Function(CircleButtonConfig value)? circleButton,
    TResult Function(JoyStickConfig value)? joyStick,
    TResult Function(DPadConfig value)? dPad,
    required TResult orElse(),
  }) {
    if (dPad != null) {
      return dPad(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DPadConfigImplToJson(
      this,
    );
  }
}

abstract class DPadConfig extends TouchInputConfig {
  const factory DPadConfig(
      {@JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction upAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction downAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction leftAction,
      @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
      required final NesAction rightAction,
      required final double x,
      required final double y,
      final double size,
      final double deadZone}) = _$DPadConfigImpl;
  const DPadConfig._() : super._();

  factory DPadConfig.fromJson(Map<String, dynamic> json) =
      _$DPadConfigImpl.fromJson;

  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get upAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get downAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get leftAction;
  @JsonKey(fromJson: NesAction.fromCode, toJson: NesAction.toJson)
  NesAction get rightAction;
  @override
  double get x;
  @override
  double get y;
  double get size;
  double get deadZone;
  @override
  @JsonKey(ignore: true)
  _$$DPadConfigImplCopyWith<_$DPadConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
