import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

sealed class FilePickerState {}

class FilePickerLoading extends FilePickerState {}

class FilePickerError extends FilePickerState {
  FilePickerError(this.message);

  final String message;
}

class FilePickerData extends FilePickerState {
  FilePickerData({required this.path, required this.files});

  final String path;

  final List<FilesystemFile> files;
}
