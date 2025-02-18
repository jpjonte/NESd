enum FileSystemFileType { file, directory }

class FileSystemFile {
  const FileSystemFile({required this.path, required this.type});

  final String path;
  final FileSystemFileType type;
}
