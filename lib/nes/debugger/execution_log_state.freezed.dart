// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'execution_log_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ExecutionLogState {
  bool get enabled => throw _privateConstructorUsedError;
  List<ExecutionLogLine> get lines => throw _privateConstructorUsedError;

  /// Create a copy of ExecutionLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExecutionLogStateCopyWith<ExecutionLogState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExecutionLogStateCopyWith<$Res> {
  factory $ExecutionLogStateCopyWith(
    ExecutionLogState value,
    $Res Function(ExecutionLogState) then,
  ) = _$ExecutionLogStateCopyWithImpl<$Res, ExecutionLogState>;
  @useResult
  $Res call({bool enabled, List<ExecutionLogLine> lines});
}

/// @nodoc
class _$ExecutionLogStateCopyWithImpl<$Res, $Val extends ExecutionLogState>
    implements $ExecutionLogStateCopyWith<$Res> {
  _$ExecutionLogStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExecutionLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? enabled = null, Object? lines = null}) {
    return _then(
      _value.copyWith(
            enabled:
                null == enabled
                    ? _value.enabled
                    : enabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            lines:
                null == lines
                    ? _value.lines
                    : lines // ignore: cast_nullable_to_non_nullable
                        as List<ExecutionLogLine>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExecutionLogStateImplCopyWith<$Res>
    implements $ExecutionLogStateCopyWith<$Res> {
  factory _$$ExecutionLogStateImplCopyWith(
    _$ExecutionLogStateImpl value,
    $Res Function(_$ExecutionLogStateImpl) then,
  ) = __$$ExecutionLogStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool enabled, List<ExecutionLogLine> lines});
}

/// @nodoc
class __$$ExecutionLogStateImplCopyWithImpl<$Res>
    extends _$ExecutionLogStateCopyWithImpl<$Res, _$ExecutionLogStateImpl>
    implements _$$ExecutionLogStateImplCopyWith<$Res> {
  __$$ExecutionLogStateImplCopyWithImpl(
    _$ExecutionLogStateImpl _value,
    $Res Function(_$ExecutionLogStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExecutionLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? enabled = null, Object? lines = null}) {
    return _then(
      _$ExecutionLogStateImpl(
        enabled:
            null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        lines:
            null == lines
                ? _value._lines
                : lines // ignore: cast_nullable_to_non_nullable
                    as List<ExecutionLogLine>,
      ),
    );
  }
}

/// @nodoc

class _$ExecutionLogStateImpl implements _ExecutionLogState {
  const _$ExecutionLogStateImpl({
    this.enabled = false,
    final List<ExecutionLogLine> lines = const [],
  }) : _lines = lines;

  @override
  @JsonKey()
  final bool enabled;
  final List<ExecutionLogLine> _lines;
  @override
  @JsonKey()
  List<ExecutionLogLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'ExecutionLogState(enabled: $enabled, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExecutionLogStateImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    const DeepCollectionEquality().hash(_lines),
  );

  /// Create a copy of ExecutionLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExecutionLogStateImplCopyWith<_$ExecutionLogStateImpl> get copyWith =>
      __$$ExecutionLogStateImplCopyWithImpl<_$ExecutionLogStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ExecutionLogState implements ExecutionLogState {
  const factory _ExecutionLogState({
    final bool enabled,
    final List<ExecutionLogLine> lines,
  }) = _$ExecutionLogStateImpl;

  @override
  bool get enabled;
  @override
  List<ExecutionLogLine> get lines;

  /// Create a copy of ExecutionLogState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExecutionLogStateImplCopyWith<_$ExecutionLogStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
