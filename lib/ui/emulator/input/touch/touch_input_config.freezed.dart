// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'touch_input_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
TouchInputConfig _$TouchInputConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'rectangleButton':
          return RectangleButtonConfig.fromJson(
            json
          );
                case 'circleButton':
          return CircleButtonConfig.fromJson(
            json
          );
                case 'joyStick':
          return JoyStickConfig.fromJson(
            json
          );
                case 'dPad':
          return DPadConfig.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'TouchInputConfig',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$TouchInputConfig {

 double get x; double get y;
/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TouchInputConfigCopyWith<TouchInputConfig> get copyWith => _$TouchInputConfigCopyWithImpl<TouchInputConfig>(this as TouchInputConfig, _$identity);

  /// Serializes this TouchInputConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TouchInputConfig&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'TouchInputConfig(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $TouchInputConfigCopyWith<$Res>  {
  factory $TouchInputConfigCopyWith(TouchInputConfig value, $Res Function(TouchInputConfig) _then) = _$TouchInputConfigCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$TouchInputConfigCopyWithImpl<$Res>
    implements $TouchInputConfigCopyWith<$Res> {
  _$TouchInputConfigCopyWithImpl(this._self, this._then);

  final TouchInputConfig _self;
  final $Res Function(TouchInputConfig) _then;

/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc
@JsonSerializable()

class RectangleButtonConfig extends TouchInputConfig {
  const RectangleButtonConfig({required this.x, required this.y, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.action, this.width = 60, this.height = 60, this.label = '', final  String? $type}): $type = $type ?? 'rectangleButton',super._();
  factory RectangleButtonConfig.fromJson(Map<String, dynamic> json) => _$RectangleButtonConfigFromJson(json);

@override final  double x;
@override final  double y;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? action;
@JsonKey() final  double width;
@JsonKey() final  double height;
@JsonKey() final  String label;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RectangleButtonConfigCopyWith<RectangleButtonConfig> get copyWith => _$RectangleButtonConfigCopyWithImpl<RectangleButtonConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RectangleButtonConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RectangleButtonConfig&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.action, action) || other.action == action)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,action,width,height,label);

@override
String toString() {
  return 'TouchInputConfig.rectangleButton(x: $x, y: $y, action: $action, width: $width, height: $height, label: $label)';
}


}

/// @nodoc
abstract mixin class $RectangleButtonConfigCopyWith<$Res> implements $TouchInputConfigCopyWith<$Res> {
  factory $RectangleButtonConfigCopyWith(RectangleButtonConfig value, $Res Function(RectangleButtonConfig) _then) = _$RectangleButtonConfigCopyWithImpl;
@override @useResult
$Res call({
 double x, double y,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? action, double width, double height, String label
});




}
/// @nodoc
class _$RectangleButtonConfigCopyWithImpl<$Res>
    implements $RectangleButtonConfigCopyWith<$Res> {
  _$RectangleButtonConfigCopyWithImpl(this._self, this._then);

  final RectangleButtonConfig _self;
  final $Res Function(RectangleButtonConfig) _then;

/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? action = freezed,Object? width = null,Object? height = null,Object? label = null,}) {
  return _then(RectangleButtonConfig(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as InputAction?,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CircleButtonConfig extends TouchInputConfig {
  const CircleButtonConfig({required this.x, required this.y, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.action, this.size = 75, this.label = '', final  String? $type}): $type = $type ?? 'circleButton',super._();
  factory CircleButtonConfig.fromJson(Map<String, dynamic> json) => _$CircleButtonConfigFromJson(json);

@override final  double x;
@override final  double y;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? action;
@JsonKey() final  double size;
@JsonKey() final  String label;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CircleButtonConfigCopyWith<CircleButtonConfig> get copyWith => _$CircleButtonConfigCopyWithImpl<CircleButtonConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CircleButtonConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CircleButtonConfig&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.action, action) || other.action == action)&&(identical(other.size, size) || other.size == size)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,action,size,label);

@override
String toString() {
  return 'TouchInputConfig.circleButton(x: $x, y: $y, action: $action, size: $size, label: $label)';
}


}

/// @nodoc
abstract mixin class $CircleButtonConfigCopyWith<$Res> implements $TouchInputConfigCopyWith<$Res> {
  factory $CircleButtonConfigCopyWith(CircleButtonConfig value, $Res Function(CircleButtonConfig) _then) = _$CircleButtonConfigCopyWithImpl;
@override @useResult
$Res call({
 double x, double y,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? action, double size, String label
});




}
/// @nodoc
class _$CircleButtonConfigCopyWithImpl<$Res>
    implements $CircleButtonConfigCopyWith<$Res> {
  _$CircleButtonConfigCopyWithImpl(this._self, this._then);

  final CircleButtonConfig _self;
  final $Res Function(CircleButtonConfig) _then;

/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? action = freezed,Object? size = null,Object? label = null,}) {
  return _then(CircleButtonConfig(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as InputAction?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class JoyStickConfig extends TouchInputConfig {
  const JoyStickConfig({required this.x, required this.y, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.upAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.downAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.leftAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.rightAction, this.size = 150, this.innerSize = 60, this.deadZone = 0.25, final  String? $type}): $type = $type ?? 'joyStick',super._();
  factory JoyStickConfig.fromJson(Map<String, dynamic> json) => _$JoyStickConfigFromJson(json);

@override final  double x;
@override final  double y;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? upAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? downAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? leftAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? rightAction;
@JsonKey() final  double size;
@JsonKey() final  double innerSize;
@JsonKey() final  double deadZone;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoyStickConfigCopyWith<JoyStickConfig> get copyWith => _$JoyStickConfigCopyWithImpl<JoyStickConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoyStickConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoyStickConfig&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.upAction, upAction) || other.upAction == upAction)&&(identical(other.downAction, downAction) || other.downAction == downAction)&&(identical(other.leftAction, leftAction) || other.leftAction == leftAction)&&(identical(other.rightAction, rightAction) || other.rightAction == rightAction)&&(identical(other.size, size) || other.size == size)&&(identical(other.innerSize, innerSize) || other.innerSize == innerSize)&&(identical(other.deadZone, deadZone) || other.deadZone == deadZone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,upAction,downAction,leftAction,rightAction,size,innerSize,deadZone);

@override
String toString() {
  return 'TouchInputConfig.joyStick(x: $x, y: $y, upAction: $upAction, downAction: $downAction, leftAction: $leftAction, rightAction: $rightAction, size: $size, innerSize: $innerSize, deadZone: $deadZone)';
}


}

/// @nodoc
abstract mixin class $JoyStickConfigCopyWith<$Res> implements $TouchInputConfigCopyWith<$Res> {
  factory $JoyStickConfigCopyWith(JoyStickConfig value, $Res Function(JoyStickConfig) _then) = _$JoyStickConfigCopyWithImpl;
@override @useResult
$Res call({
 double x, double y,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? upAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? downAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? leftAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? rightAction, double size, double innerSize, double deadZone
});




}
/// @nodoc
class _$JoyStickConfigCopyWithImpl<$Res>
    implements $JoyStickConfigCopyWith<$Res> {
  _$JoyStickConfigCopyWithImpl(this._self, this._then);

  final JoyStickConfig _self;
  final $Res Function(JoyStickConfig) _then;

/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? upAction = freezed,Object? downAction = freezed,Object? leftAction = freezed,Object? rightAction = freezed,Object? size = null,Object? innerSize = null,Object? deadZone = null,}) {
  return _then(JoyStickConfig(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,upAction: freezed == upAction ? _self.upAction : upAction // ignore: cast_nullable_to_non_nullable
as InputAction?,downAction: freezed == downAction ? _self.downAction : downAction // ignore: cast_nullable_to_non_nullable
as InputAction?,leftAction: freezed == leftAction ? _self.leftAction : leftAction // ignore: cast_nullable_to_non_nullable
as InputAction?,rightAction: freezed == rightAction ? _self.rightAction : rightAction // ignore: cast_nullable_to_non_nullable
as InputAction?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,innerSize: null == innerSize ? _self.innerSize : innerSize // ignore: cast_nullable_to_non_nullable
as double,deadZone: null == deadZone ? _self.deadZone : deadZone // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DPadConfig extends TouchInputConfig {
  const DPadConfig({required this.x, required this.y, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.upAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.downAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.leftAction, @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) this.rightAction, this.size = 150, this.deadZone = 0.25, final  String? $type}): $type = $type ?? 'dPad',super._();
  factory DPadConfig.fromJson(Map<String, dynamic> json) => _$DPadConfigFromJson(json);

@override final  double x;
@override final  double y;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? upAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? downAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? leftAction;
@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) final  InputAction? rightAction;
@JsonKey() final  double size;
@JsonKey() final  double deadZone;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DPadConfigCopyWith<DPadConfig> get copyWith => _$DPadConfigCopyWithImpl<DPadConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DPadConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DPadConfig&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.upAction, upAction) || other.upAction == upAction)&&(identical(other.downAction, downAction) || other.downAction == downAction)&&(identical(other.leftAction, leftAction) || other.leftAction == leftAction)&&(identical(other.rightAction, rightAction) || other.rightAction == rightAction)&&(identical(other.size, size) || other.size == size)&&(identical(other.deadZone, deadZone) || other.deadZone == deadZone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,upAction,downAction,leftAction,rightAction,size,deadZone);

@override
String toString() {
  return 'TouchInputConfig.dPad(x: $x, y: $y, upAction: $upAction, downAction: $downAction, leftAction: $leftAction, rightAction: $rightAction, size: $size, deadZone: $deadZone)';
}


}

/// @nodoc
abstract mixin class $DPadConfigCopyWith<$Res> implements $TouchInputConfigCopyWith<$Res> {
  factory $DPadConfigCopyWith(DPadConfig value, $Res Function(DPadConfig) _then) = _$DPadConfigCopyWithImpl;
@override @useResult
$Res call({
 double x, double y,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? upAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? downAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? leftAction,@JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson) InputAction? rightAction, double size, double deadZone
});




}
/// @nodoc
class _$DPadConfigCopyWithImpl<$Res>
    implements $DPadConfigCopyWith<$Res> {
  _$DPadConfigCopyWithImpl(this._self, this._then);

  final DPadConfig _self;
  final $Res Function(DPadConfig) _then;

/// Create a copy of TouchInputConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? upAction = freezed,Object? downAction = freezed,Object? leftAction = freezed,Object? rightAction = freezed,Object? size = null,Object? deadZone = null,}) {
  return _then(DPadConfig(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,upAction: freezed == upAction ? _self.upAction : upAction // ignore: cast_nullable_to_non_nullable
as InputAction?,downAction: freezed == downAction ? _self.downAction : downAction // ignore: cast_nullable_to_non_nullable
as InputAction?,leftAction: freezed == leftAction ? _self.leftAction : leftAction // ignore: cast_nullable_to_non_nullable
as InputAction?,rightAction: freezed == rightAction ? _self.rightAction : rightAction // ignore: cast_nullable_to_non_nullable
as InputAction?,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,deadZone: null == deadZone ? _self.deadZone : deadZone // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
