// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debug_overlay.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DebugOverlayState {
  double get frameTime => throw _privateConstructorUsedError;
  double get fps => throw _privateConstructorUsedError;
  double get sleepBudget => throw _privateConstructorUsedError;

  /// Create a copy of DebugOverlayState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DebugOverlayStateCopyWith<DebugOverlayState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DebugOverlayStateCopyWith<$Res> {
  factory $DebugOverlayStateCopyWith(
    DebugOverlayState value,
    $Res Function(DebugOverlayState) then,
  ) = _$DebugOverlayStateCopyWithImpl<$Res, DebugOverlayState>;
  @useResult
  $Res call({double frameTime, double fps, double sleepBudget});
}

/// @nodoc
class _$DebugOverlayStateCopyWithImpl<$Res, $Val extends DebugOverlayState>
    implements $DebugOverlayStateCopyWith<$Res> {
  _$DebugOverlayStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DebugOverlayState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameTime = null,
    Object? fps = null,
    Object? sleepBudget = null,
  }) {
    return _then(
      _value.copyWith(
            frameTime:
                null == frameTime
                    ? _value.frameTime
                    : frameTime // ignore: cast_nullable_to_non_nullable
                        as double,
            fps:
                null == fps
                    ? _value.fps
                    : fps // ignore: cast_nullable_to_non_nullable
                        as double,
            sleepBudget:
                null == sleepBudget
                    ? _value.sleepBudget
                    : sleepBudget // ignore: cast_nullable_to_non_nullable
                        as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DebugOverlayStateImplCopyWith<$Res>
    implements $DebugOverlayStateCopyWith<$Res> {
  factory _$$DebugOverlayStateImplCopyWith(
    _$DebugOverlayStateImpl value,
    $Res Function(_$DebugOverlayStateImpl) then,
  ) = __$$DebugOverlayStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double frameTime, double fps, double sleepBudget});
}

/// @nodoc
class __$$DebugOverlayStateImplCopyWithImpl<$Res>
    extends _$DebugOverlayStateCopyWithImpl<$Res, _$DebugOverlayStateImpl>
    implements _$$DebugOverlayStateImplCopyWith<$Res> {
  __$$DebugOverlayStateImplCopyWithImpl(
    _$DebugOverlayStateImpl _value,
    $Res Function(_$DebugOverlayStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DebugOverlayState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameTime = null,
    Object? fps = null,
    Object? sleepBudget = null,
  }) {
    return _then(
      _$DebugOverlayStateImpl(
        frameTime:
            null == frameTime
                ? _value.frameTime
                : frameTime // ignore: cast_nullable_to_non_nullable
                    as double,
        fps:
            null == fps
                ? _value.fps
                : fps // ignore: cast_nullable_to_non_nullable
                    as double,
        sleepBudget:
            null == sleepBudget
                ? _value.sleepBudget
                : sleepBudget // ignore: cast_nullable_to_non_nullable
                    as double,
      ),
    );
  }
}

/// @nodoc

class _$DebugOverlayStateImpl implements _DebugOverlayState {
  const _$DebugOverlayStateImpl({
    this.frameTime = 0,
    this.fps = 0,
    this.sleepBudget = 0,
  });

  @override
  @JsonKey()
  final double frameTime;
  @override
  @JsonKey()
  final double fps;
  @override
  @JsonKey()
  final double sleepBudget;

  @override
  String toString() {
    return 'DebugOverlayState(frameTime: $frameTime, fps: $fps, sleepBudget: $sleepBudget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DebugOverlayStateImpl &&
            (identical(other.frameTime, frameTime) ||
                other.frameTime == frameTime) &&
            (identical(other.fps, fps) || other.fps == fps) &&
            (identical(other.sleepBudget, sleepBudget) ||
                other.sleepBudget == sleepBudget));
  }

  @override
  int get hashCode => Object.hash(runtimeType, frameTime, fps, sleepBudget);

  /// Create a copy of DebugOverlayState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DebugOverlayStateImplCopyWith<_$DebugOverlayStateImpl> get copyWith =>
      __$$DebugOverlayStateImplCopyWithImpl<_$DebugOverlayStateImpl>(
        this,
        _$identity,
      );
}

abstract class _DebugOverlayState implements DebugOverlayState {
  const factory _DebugOverlayState({
    final double frameTime,
    final double fps,
    final double sleepBudget,
  }) = _$DebugOverlayStateImpl;

  @override
  double get frameTime;
  @override
  double get fps;
  @override
  double get sleepBudget;

  /// Create a copy of DebugOverlayState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DebugOverlayStateImplCopyWith<_$DebugOverlayStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
