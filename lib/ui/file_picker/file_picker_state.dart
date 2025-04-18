import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

part 'file_picker_state.freezed.dart';

sealed class FilePickerState {}

class FilePickerLoading extends FilePickerState {}

class FilePickerError extends FilePickerState {
  FilePickerError(this.message);

  final String message;
}

@freezed
class FilePickerData extends FilePickerState with _$FilePickerData {
  FilePickerData({
    required this.directory,
    required this.files,
    this.refreshing = false,
  });

  @override
  final FilesystemFile directory;

  @override
  final List<FilesystemFile> files;

  @override
  final bool refreshing;
}
