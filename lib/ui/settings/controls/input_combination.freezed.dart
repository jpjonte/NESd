// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input_combination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
InputCombination _$InputCombinationFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'gamepad':
          return GamepadInputCombination.fromJson(
            json
          );
        
          default:
            return KeyboardInputCombination.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$InputCombination {



  /// Serializes this InputCombination to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputCombination);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InputCombination()';
}


}

/// @nodoc
class $InputCombinationCopyWith<$Res>  {
$InputCombinationCopyWith(InputCombination _, $Res Function(InputCombination) __);
}


/// @nodoc
@JsonSerializable()

class KeyboardInputCombination extends InputCombination {
  const KeyboardInputCombination(@JsonKey(fromJson: keysFromJson, toJson: keysToJson) final  Set<LogicalKeyboardKey> keys, {final  String? $type}): _keys = keys,$type = $type ?? 'keyboard',super._();
  factory KeyboardInputCombination.fromJson(Map<String, dynamic> json) => _$KeyboardInputCombinationFromJson(json);

 final  Set<LogicalKeyboardKey> _keys;
@JsonKey(fromJson: keysFromJson, toJson: keysToJson) Set<LogicalKeyboardKey> get keys {
  if (_keys is EqualUnmodifiableSetView) return _keys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_keys);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of InputCombination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyboardInputCombinationCopyWith<KeyboardInputCombination> get copyWith => _$KeyboardInputCombinationCopyWithImpl<KeyboardInputCombination>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeyboardInputCombinationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyboardInputCombination&&const DeepCollectionEquality().equals(other._keys, _keys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_keys));

@override
String toString() {
  return 'InputCombination.keyboard(keys: $keys)';
}


}

/// @nodoc
abstract mixin class $KeyboardInputCombinationCopyWith<$Res> implements $InputCombinationCopyWith<$Res> {
  factory $KeyboardInputCombinationCopyWith(KeyboardInputCombination value, $Res Function(KeyboardInputCombination) _then) = _$KeyboardInputCombinationCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: keysFromJson, toJson: keysToJson) Set<LogicalKeyboardKey> keys
});




}
/// @nodoc
class _$KeyboardInputCombinationCopyWithImpl<$Res>
    implements $KeyboardInputCombinationCopyWith<$Res> {
  _$KeyboardInputCombinationCopyWithImpl(this._self, this._then);

  final KeyboardInputCombination _self;
  final $Res Function(KeyboardInputCombination) _then;

/// Create a copy of InputCombination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? keys = null,}) {
  return _then(KeyboardInputCombination(
null == keys ? _self._keys : keys // ignore: cast_nullable_to_non_nullable
as Set<LogicalKeyboardKey>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GamepadInputCombination extends InputCombination {
  const GamepadInputCombination({required this.gamepadId, required final  Set<GamepadInput> inputs, this.gamepadName = 'Unknown', final  String? $type}): _inputs = inputs,$type = $type ?? 'gamepad',super._();
  factory GamepadInputCombination.fromJson(Map<String, dynamic> json) => _$GamepadInputCombinationFromJson(json);

 final  String gamepadId;
 final  Set<GamepadInput> _inputs;
 Set<GamepadInput> get inputs {
  if (_inputs is EqualUnmodifiableSetView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inputs);
}

@JsonKey() final  String gamepadName;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of InputCombination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GamepadInputCombinationCopyWith<GamepadInputCombination> get copyWith => _$GamepadInputCombinationCopyWithImpl<GamepadInputCombination>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GamepadInputCombinationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GamepadInputCombination&&(identical(other.gamepadId, gamepadId) || other.gamepadId == gamepadId)&&const DeepCollectionEquality().equals(other._inputs, _inputs)&&(identical(other.gamepadName, gamepadName) || other.gamepadName == gamepadName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gamepadId,const DeepCollectionEquality().hash(_inputs),gamepadName);

@override
String toString() {
  return 'InputCombination.gamepad(gamepadId: $gamepadId, inputs: $inputs, gamepadName: $gamepadName)';
}


}

/// @nodoc
abstract mixin class $GamepadInputCombinationCopyWith<$Res> implements $InputCombinationCopyWith<$Res> {
  factory $GamepadInputCombinationCopyWith(GamepadInputCombination value, $Res Function(GamepadInputCombination) _then) = _$GamepadInputCombinationCopyWithImpl;
@useResult
$Res call({
 String gamepadId, Set<GamepadInput> inputs, String gamepadName
});




}
/// @nodoc
class _$GamepadInputCombinationCopyWithImpl<$Res>
    implements $GamepadInputCombinationCopyWith<$Res> {
  _$GamepadInputCombinationCopyWithImpl(this._self, this._then);

  final GamepadInputCombination _self;
  final $Res Function(GamepadInputCombination) _then;

/// Create a copy of InputCombination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gamepadId = null,Object? inputs = null,Object? gamepadName = null,}) {
  return _then(GamepadInputCombination(
gamepadId: null == gamepadId ? _self.gamepadId : gamepadId // ignore: cast_nullable_to_non_nullable
as String,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as Set<GamepadInput>,gamepadName: null == gamepadName ? _self.gamepadName : gamepadName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
