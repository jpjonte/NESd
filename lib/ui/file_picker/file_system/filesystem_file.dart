import 'package:freezed_annotation/freezed_annotation.dart';

part 'filesystem_file.g.dart';

enum FilesystemFileType { file, directory }

@JsonSerializable()
class FilesystemFile {
  const FilesystemFile({
    required this.path,
    required this.name,
    required this.type,
  });

  final String path;
  final String name;
  final FilesystemFileType type;

  factory FilesystemFile.fromJson(Map<String, dynamic> json) =>
      _$FilesystemFileFromJson(json);

  Map<String, dynamic> toJson() => _$FilesystemFileToJson(this);
}
