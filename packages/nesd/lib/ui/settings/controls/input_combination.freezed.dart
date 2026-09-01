// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input_combination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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


/// Adds pattern-matching-related methods to [InputCombination].
extension InputCombinationPatterns on InputCombination {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KeyboardInputCombination value)?  keyboard,TResult Function( GamepadInputCombination value)?  gamepad,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KeyboardInputCombination() when keyboard != null:
return keyboard(_that);case GamepadInputCombination() when gamepad != null:
return gamepad(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KeyboardInputCombination value)  keyboard,required TResult Function( GamepadInputCombination value)  gamepad,}){
final _that = this;
switch (_that) {
case KeyboardInputCombination():
return keyboard(_that);case GamepadInputCombination():
return gamepad(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KeyboardInputCombination value)?  keyboard,TResult? Function( GamepadInputCombination value)?  gamepad,}){
final _that = this;
switch (_that) {
case KeyboardInputCombination() when keyboard != null:
return keyboard(_that);case GamepadInputCombination() when gamepad != null:
return gamepad(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(fromJson: keysFromJson, toJson: keysToJson)  Set<LogicalKeyboardKey> keys)?  keyboard,TResult Function( int slot,  Set<GamepadInput> inputs)?  gamepad,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KeyboardInputCombination() when keyboard != null:
return keyboard(_that.keys);case GamepadInputCombination() when gamepad != null:
return gamepad(_that.slot,_that.inputs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(fromJson: keysFromJson, toJson: keysToJson)  Set<LogicalKeyboardKey> keys)  keyboard,required TResult Function( int slot,  Set<GamepadInput> inputs)  gamepad,}) {final _that = this;
switch (_that) {
case KeyboardInputCombination():
return keyboard(_that.keys);case GamepadInputCombination():
return gamepad(_that.slot,_that.inputs);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(fromJson: keysFromJson, toJson: keysToJson)  Set<LogicalKeyboardKey> keys)?  keyboard,TResult? Function( int slot,  Set<GamepadInput> inputs)?  gamepad,}) {final _that = this;
switch (_that) {
case KeyboardInputCombination() when keyboard != null:
return keyboard(_that.keys);case GamepadInputCombination() when gamepad != null:
return gamepad(_that.slot,_that.inputs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class KeyboardInputCombination extends InputCombination {
  const KeyboardInputCombination(@JsonKey(fromJson: keysFromJson, toJson: keysToJson)  Set<LogicalKeyboardKey> keys, { String? $type}): _keys = keys,$type = $type ?? 'keyboard',super._();
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyboardInputCombination&&const DeepCollectionEquality().equals(other.keys, _keys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_keys));
}

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
  const GamepadInputCombination({required this.slot, required  Set<GamepadInput> inputs,  String? $type}): _inputs = inputs,$type = $type ?? 'gamepad',super._();
  factory GamepadInputCombination.fromJson(Map<String, dynamic> json) => _$GamepadInputCombinationFromJson(json);

 final  int slot;
 final  Set<GamepadInput> _inputs;
 Set<GamepadInput> get inputs {
  if (_inputs is EqualUnmodifiableSetView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inputs);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GamepadInputCombination&&(identical(other.slot, slot) || other.slot == slot)&&const DeepCollectionEquality().equals(other.inputs, _inputs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,slot,const DeepCollectionEquality().hash(_inputs));
}

@override
String toString() {
    return 'InputCombination.gamepad(slot: $slot, inputs: $inputs)';
}


}

/// @nodoc
abstract mixin class $GamepadInputCombinationCopyWith<$Res> implements $InputCombinationCopyWith<$Res> {
  factory $GamepadInputCombinationCopyWith(GamepadInputCombination value, $Res Function(GamepadInputCombination) _then) = _$GamepadInputCombinationCopyWithImpl;
@useResult
$Res call({
 int slot, Set<GamepadInput> inputs
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
@pragma('vm:prefer-inline') $Res call({Object? slot = null,Object? inputs = null,}) {
  return _then(GamepadInputCombination(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as int,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as Set<GamepadInput>,
  ));
}


}

// dart format on
