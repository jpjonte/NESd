// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
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


// dart format on
