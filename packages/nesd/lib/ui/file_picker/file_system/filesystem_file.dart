import 'package:freezed_annotation/freezed_annotation.dart';

part 'filesystem_file.g.dart';

enum FilesystemFileType { file, directory }

@JsonSerializable()
@immutable
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilesystemFile &&
          other.path == path &&
          other.name == name &&
          other.type == type;

  @override
  int get hashCode => Object.hash(path, name, type);
}
