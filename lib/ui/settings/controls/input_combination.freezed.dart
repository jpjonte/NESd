// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input_combination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InputCombination _$InputCombinationFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'gamepad':
      return GamepadInputCombination.fromJson(json);

    default:
      return KeyboardInputCombination.fromJson(json);
  }
}

/// @nodoc
mixin _$InputCombination {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)
        keyboard,
    required TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)
        gamepad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult? Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(KeyboardInputCombination value) keyboard,
    required TResult Function(GamepadInputCombination value) gamepad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(KeyboardInputCombination value)? keyboard,
    TResult? Function(GamepadInputCombination value)? gamepad,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(KeyboardInputCombination value)? keyboard,
    TResult Function(GamepadInputCombination value)? gamepad,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this InputCombination to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InputCombinationCopyWith<$Res> {
  factory $InputCombinationCopyWith(
          InputCombination value, $Res Function(InputCombination) then) =
      _$InputCombinationCopyWithImpl<$Res, InputCombination>;
}

/// @nodoc
class _$InputCombinationCopyWithImpl<$Res, $Val extends InputCombination>
    implements $InputCombinationCopyWith<$Res> {
  _$InputCombinationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$KeyboardInputCombinationImplCopyWith<$Res> {
  factory _$$KeyboardInputCombinationImplCopyWith(
          _$KeyboardInputCombinationImpl value,
          $Res Function(_$KeyboardInputCombinationImpl) then) =
      __$$KeyboardInputCombinationImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: keysFromJson, toJson: keysToJson)
      Set<LogicalKeyboardKey> keys});
}

/// @nodoc
class __$$KeyboardInputCombinationImplCopyWithImpl<$Res>
    extends _$InputCombinationCopyWithImpl<$Res, _$KeyboardInputCombinationImpl>
    implements _$$KeyboardInputCombinationImplCopyWith<$Res> {
  __$$KeyboardInputCombinationImplCopyWithImpl(
      _$KeyboardInputCombinationImpl _value,
      $Res Function(_$KeyboardInputCombinationImpl) _then)
      : super(_value, _then);

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keys = null,
  }) {
    return _then(_$KeyboardInputCombinationImpl(
      null == keys
          ? _value._keys
          : keys // ignore: cast_nullable_to_non_nullable
              as Set<LogicalKeyboardKey>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KeyboardInputCombinationImpl extends KeyboardInputCombination {
  const _$KeyboardInputCombinationImpl(
      @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
      final Set<LogicalKeyboardKey> keys,
      {final String? $type})
      : _keys = keys,
        $type = $type ?? 'keyboard',
        super._();

  factory _$KeyboardInputCombinationImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeyboardInputCombinationImplFromJson(json);

  final Set<LogicalKeyboardKey> _keys;
  @override
  @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
  Set<LogicalKeyboardKey> get keys {
    if (_keys is EqualUnmodifiableSetView) return _keys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_keys);
  }

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'InputCombination.keyboard(keys: $keys)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyboardInputCombinationImpl &&
            const DeepCollectionEquality().equals(other._keys, _keys));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_keys));

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KeyboardInputCombinationImplCopyWith<_$KeyboardInputCombinationImpl>
      get copyWith => __$$KeyboardInputCombinationImplCopyWithImpl<
          _$KeyboardInputCombinationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)
        keyboard,
    required TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)
        gamepad,
  }) {
    return keyboard(keys);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult? Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
  }) {
    return keyboard?.call(keys);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
    required TResult orElse(),
  }) {
    if (keyboard != null) {
      return keyboard(keys);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(KeyboardInputCombination value) keyboard,
    required TResult Function(GamepadInputCombination value) gamepad,
  }) {
    return keyboard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(KeyboardInputCombination value)? keyboard,
    TResult? Function(GamepadInputCombination value)? gamepad,
  }) {
    return keyboard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(KeyboardInputCombination value)? keyboard,
    TResult Function(GamepadInputCombination value)? gamepad,
    required TResult orElse(),
  }) {
    if (keyboard != null) {
      return keyboard(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$KeyboardInputCombinationImplToJson(
      this,
    );
  }
}

abstract class KeyboardInputCombination extends InputCombination {
  const factory KeyboardInputCombination(
      @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
      final Set<LogicalKeyboardKey> keys) = _$KeyboardInputCombinationImpl;
  const KeyboardInputCombination._() : super._();

  factory KeyboardInputCombination.fromJson(Map<String, dynamic> json) =
      _$KeyboardInputCombinationImpl.fromJson;

  @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
  Set<LogicalKeyboardKey> get keys;

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KeyboardInputCombinationImplCopyWith<_$KeyboardInputCombinationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GamepadInputCombinationImplCopyWith<$Res> {
  factory _$$GamepadInputCombinationImplCopyWith(
          _$GamepadInputCombinationImpl value,
          $Res Function(_$GamepadInputCombinationImpl) then) =
      __$$GamepadInputCombinationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String gamepadId, Set<GamepadInput> inputs, String gamepadName});
}

/// @nodoc
class __$$GamepadInputCombinationImplCopyWithImpl<$Res>
    extends _$InputCombinationCopyWithImpl<$Res, _$GamepadInputCombinationImpl>
    implements _$$GamepadInputCombinationImplCopyWith<$Res> {
  __$$GamepadInputCombinationImplCopyWithImpl(
      _$GamepadInputCombinationImpl _value,
      $Res Function(_$GamepadInputCombinationImpl) _then)
      : super(_value, _then);

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamepadId = null,
    Object? inputs = null,
    Object? gamepadName = null,
  }) {
    return _then(_$GamepadInputCombinationImpl(
      gamepadId: null == gamepadId
          ? _value.gamepadId
          : gamepadId // ignore: cast_nullable_to_non_nullable
              as String,
      inputs: null == inputs
          ? _value._inputs
          : inputs // ignore: cast_nullable_to_non_nullable
              as Set<GamepadInput>,
      gamepadName: null == gamepadName
          ? _value.gamepadName
          : gamepadName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GamepadInputCombinationImpl extends GamepadInputCombination {
  const _$GamepadInputCombinationImpl(
      {required this.gamepadId,
      required final Set<GamepadInput> inputs,
      this.gamepadName = 'Unknown',
      final String? $type})
      : _inputs = inputs,
        $type = $type ?? 'gamepad',
        super._();

  factory _$GamepadInputCombinationImpl.fromJson(Map<String, dynamic> json) =>
      _$$GamepadInputCombinationImplFromJson(json);

  @override
  final String gamepadId;
  final Set<GamepadInput> _inputs;
  @override
  Set<GamepadInput> get inputs {
    if (_inputs is EqualUnmodifiableSetView) return _inputs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_inputs);
  }

  @override
  @JsonKey()
  final String gamepadName;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'InputCombination.gamepad(gamepadId: $gamepadId, inputs: $inputs, gamepadName: $gamepadName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GamepadInputCombinationImpl &&
            (identical(other.gamepadId, gamepadId) ||
                other.gamepadId == gamepadId) &&
            const DeepCollectionEquality().equals(other._inputs, _inputs) &&
            (identical(other.gamepadName, gamepadName) ||
                other.gamepadName == gamepadName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, gamepadId,
      const DeepCollectionEquality().hash(_inputs), gamepadName);

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GamepadInputCombinationImplCopyWith<_$GamepadInputCombinationImpl>
      get copyWith => __$$GamepadInputCombinationImplCopyWithImpl<
          _$GamepadInputCombinationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)
        keyboard,
    required TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)
        gamepad,
  }) {
    return gamepad(gamepadId, inputs, gamepadName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult? Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
  }) {
    return gamepad?.call(gamepadId, inputs, gamepadName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(fromJson: keysFromJson, toJson: keysToJson)
            Set<LogicalKeyboardKey> keys)?
        keyboard,
    TResult Function(
            String gamepadId, Set<GamepadInput> inputs, String gamepadName)?
        gamepad,
    required TResult orElse(),
  }) {
    if (gamepad != null) {
      return gamepad(gamepadId, inputs, gamepadName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(KeyboardInputCombination value) keyboard,
    required TResult Function(GamepadInputCombination value) gamepad,
  }) {
    return gamepad(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(KeyboardInputCombination value)? keyboard,
    TResult? Function(GamepadInputCombination value)? gamepad,
  }) {
    return gamepad?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(KeyboardInputCombination value)? keyboard,
    TResult Function(GamepadInputCombination value)? gamepad,
    required TResult orElse(),
  }) {
    if (gamepad != null) {
      return gamepad(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GamepadInputCombinationImplToJson(
      this,
    );
  }
}

abstract class GamepadInputCombination extends InputCombination {
  const factory GamepadInputCombination(
      {required final String gamepadId,
      required final Set<GamepadInput> inputs,
      final String gamepadName}) = _$GamepadInputCombinationImpl;
  const GamepadInputCombination._() : super._();

  factory GamepadInputCombination.fromJson(Map<String, dynamic> json) =
      _$GamepadInputCombinationImpl.fromJson;

  String get gamepadId;
  Set<GamepadInput> get inputs;
  String get gamepadName;

  /// Create a copy of InputCombination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GamepadInputCombinationImplCopyWith<_$GamepadInputCombinationImpl>
      get copyWith => throw _privateConstructorUsedError;
}
