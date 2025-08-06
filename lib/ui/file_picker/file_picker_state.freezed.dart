// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FilePickerData {

 FilesystemFile get directory; List<FilesystemFile> get files; bool get refreshing;
/// Create a copy of FilePickerData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilePickerDataCopyWith<FilePickerData> get copyWith => _$FilePickerDataCopyWithImpl<FilePickerData>(this as FilePickerData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilePickerData&&(identical(other.directory, directory) || other.directory == directory)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode => Object.hash(runtimeType,directory,const DeepCollectionEquality().hash(files),refreshing);

@override
String toString() {
  return 'FilePickerData(directory: $directory, files: $files, refreshing: $refreshing)';
}


}

/// @nodoc
abstract mixin class $FilePickerDataCopyWith<$Res>  {
  factory $FilePickerDataCopyWith(FilePickerData value, $Res Function(FilePickerData) _then) = _$FilePickerDataCopyWithImpl;
@useResult
$Res call({
 FilesystemFile directory, List<FilesystemFile> files, bool refreshing
});




}
/// @nodoc
class _$FilePickerDataCopyWithImpl<$Res>
    implements $FilePickerDataCopyWith<$Res> {
  _$FilePickerDataCopyWithImpl(this._self, this._then);

  final FilePickerData _self;
  final $Res Function(FilePickerData) _then;

/// Create a copy of FilePickerData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? directory = null,Object? files = null,Object? refreshing = null,}) {
  return _then(FilePickerData(
directory: null == directory ? _self.directory : directory // ignore: cast_nullable_to_non_nullable
as FilesystemFile,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<FilesystemFile>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FilePickerData].
extension FilePickerDataPatterns on FilePickerData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
