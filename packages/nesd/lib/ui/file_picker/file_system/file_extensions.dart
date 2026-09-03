import 'package:path/path.dart' as p;

const archiveSeparator = ':';

const entryPathSeparator = '/';

String fileExtension(String path) => p.extension(path).toLowerCase();

bool isRomFile(String path) => fileExtension(path) == '.nes';

bool isZipFile(String path) => fileExtension(path) == '.zip';

bool isSevenZipFile(String path) => fileExtension(path) == '.7z';

bool isArchiveFile(String path) => isZipFile(path) || isSevenZipFile(path);

({String archivePath, String entryPath})? splitArchivePath(String path) {
  final separator = path.lastIndexOf(archiveSeparator);

  if (separator == -1) {
    return null;
  }

  final archivePath = path.substring(0, separator);

  if (!isArchiveFile(archivePath)) {
    return null;
  }

  return (archivePath: archivePath, entryPath: path.substring(separator + 1));
}

bool isWithinDirectory(String directory, String path) {
  final pathSplit = splitArchivePath(path);

  if (pathSplit == null) {
    return p.isWithin(directory, path);
  }

  final directorySplit = splitArchivePath(directory);

  if (directorySplit == null) {
    return directory == pathSplit.archivePath ||
        p.isWithin(directory, pathSplit.archivePath);
  }

  return directorySplit.archivePath == pathSplit.archivePath &&
      p.posix.isWithin(directorySplit.entryPath, pathSplit.entryPath);
}

const romPickerExtensions = ['.nes', '.zip', '.7z'];

List<String> get romFileTypeExtensions => [
  for (final extension in romPickerExtensions) extension.substring(1),
];
