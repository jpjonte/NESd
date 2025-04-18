// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filesystem_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilesystemFile _$FilesystemFileFromJson(Map<String, dynamic> json) =>
    FilesystemFile(
      path: json['path'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$FilesystemFileTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$FilesystemFileToJson(FilesystemFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'type': _$FilesystemFileTypeEnumMap[instance.type]!,
    };

const _$FilesystemFileTypeEnumMap = {
  FilesystemFileType.file: 'file',
  FilesystemFileType.directory: 'directory',
};
