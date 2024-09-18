// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'touch_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TouchEditorState {
  bool get showHint => throw _privateConstructorUsedError;
  int? get editingIndex => throw _privateConstructorUsedError;
  Orientation? get editingOrientation => throw _privateConstructorUsedError;
  TouchInputConfig? get editingConfig => throw _privateConstructorUsedError;

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TouchEditorStateCopyWith<TouchEditorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TouchEditorStateCopyWith<$Res> {
  factory $TouchEditorStateCopyWith(
          TouchEditorState value, $Res Function(TouchEditorState) then) =
      _$TouchEditorStateCopyWithImpl<$Res, TouchEditorState>;
  @useResult
  $Res call(
      {bool showHint,
      int? editingIndex,
      Orientation? editingOrientation,
      TouchInputConfig? editingConfig});

  $TouchInputConfigCopyWith<$Res>? get editingConfig;
}

/// @nodoc
class _$TouchEditorStateCopyWithImpl<$Res, $Val extends TouchEditorState>
    implements $TouchEditorStateCopyWith<$Res> {
  _$TouchEditorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showHint = null,
    Object? editingIndex = freezed,
    Object? editingOrientation = freezed,
    Object? editingConfig = freezed,
  }) {
    return _then(_value.copyWith(
      showHint: null == showHint
          ? _value.showHint
          : showHint // ignore: cast_nullable_to_non_nullable
              as bool,
      editingIndex: freezed == editingIndex
          ? _value.editingIndex
          : editingIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      editingOrientation: freezed == editingOrientation
          ? _value.editingOrientation
          : editingOrientation // ignore: cast_nullable_to_non_nullable
              as Orientation?,
      editingConfig: freezed == editingConfig
          ? _value.editingConfig
          : editingConfig // ignore: cast_nullable_to_non_nullable
              as TouchInputConfig?,
    ) as $Val);
  }

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TouchInputConfigCopyWith<$Res>? get editingConfig {
    if (_value.editingConfig == null) {
      return null;
    }

    return $TouchInputConfigCopyWith<$Res>(_value.editingConfig!, (value) {
      return _then(_value.copyWith(editingConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TouchEditorStateImplCopyWith<$Res>
    implements $TouchEditorStateCopyWith<$Res> {
  factory _$$TouchEditorStateImplCopyWith(_$TouchEditorStateImpl value,
          $Res Function(_$TouchEditorStateImpl) then) =
      __$$TouchEditorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool showHint,
      int? editingIndex,
      Orientation? editingOrientation,
      TouchInputConfig? editingConfig});

  @override
  $TouchInputConfigCopyWith<$Res>? get editingConfig;
}

/// @nodoc
class __$$TouchEditorStateImplCopyWithImpl<$Res>
    extends _$TouchEditorStateCopyWithImpl<$Res, _$TouchEditorStateImpl>
    implements _$$TouchEditorStateImplCopyWith<$Res> {
  __$$TouchEditorStateImplCopyWithImpl(_$TouchEditorStateImpl _value,
      $Res Function(_$TouchEditorStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showHint = null,
    Object? editingIndex = freezed,
    Object? editingOrientation = freezed,
    Object? editingConfig = freezed,
  }) {
    return _then(_$TouchEditorStateImpl(
      showHint: null == showHint
          ? _value.showHint
          : showHint // ignore: cast_nullable_to_non_nullable
              as bool,
      editingIndex: freezed == editingIndex
          ? _value.editingIndex
          : editingIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      editingOrientation: freezed == editingOrientation
          ? _value.editingOrientation
          : editingOrientation // ignore: cast_nullable_to_non_nullable
              as Orientation?,
      editingConfig: freezed == editingConfig
          ? _value.editingConfig
          : editingConfig // ignore: cast_nullable_to_non_nullable
              as TouchInputConfig?,
    ));
  }
}

/// @nodoc

class _$TouchEditorStateImpl implements _TouchEditorState {
  const _$TouchEditorStateImpl(
      {this.showHint = true,
      this.editingIndex = null,
      this.editingOrientation = null,
      this.editingConfig = null});

  @override
  @JsonKey()
  final bool showHint;
  @override
  @JsonKey()
  final int? editingIndex;
  @override
  @JsonKey()
  final Orientation? editingOrientation;
  @override
  @JsonKey()
  final TouchInputConfig? editingConfig;

  @override
  String toString() {
    return 'TouchEditorState(showHint: $showHint, editingIndex: $editingIndex, editingOrientation: $editingOrientation, editingConfig: $editingConfig)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TouchEditorStateImpl &&
            (identical(other.showHint, showHint) ||
                other.showHint == showHint) &&
            (identical(other.editingIndex, editingIndex) ||
                other.editingIndex == editingIndex) &&
            (identical(other.editingOrientation, editingOrientation) ||
                other.editingOrientation == editingOrientation) &&
            (identical(other.editingConfig, editingConfig) ||
                other.editingConfig == editingConfig));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, showHint, editingIndex, editingOrientation, editingConfig);

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TouchEditorStateImplCopyWith<_$TouchEditorStateImpl> get copyWith =>
      __$$TouchEditorStateImplCopyWithImpl<_$TouchEditorStateImpl>(
          this, _$identity);
}

abstract class _TouchEditorState implements TouchEditorState {
  const factory _TouchEditorState(
      {final bool showHint,
      final int? editingIndex,
      final Orientation? editingOrientation,
      final TouchInputConfig? editingConfig}) = _$TouchEditorStateImpl;

  @override
  bool get showHint;
  @override
  int? get editingIndex;
  @override
  Orientation? get editingOrientation;
  @override
  TouchInputConfig? get editingConfig;

  /// Create a copy of TouchEditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TouchEditorStateImplCopyWith<_$TouchEditorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
