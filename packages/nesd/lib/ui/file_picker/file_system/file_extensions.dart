import 'package:path/path.dart' as p;

const archiveSeparator = ':';

String fileExtension(String path) => p.extension(path).toLowerCase();

bool isRomFile(String path) => fileExtension(path) == '.nes';

bool isZipFile(String path) => fileExtension(path) == '.zip';

bool isSevenZipFile(String path) => fileExtension(path) == '.7z';

bool isArchiveFile(String path) => isZipFile(path) || isSevenZipFile(path);

const romPickerExtensions = ['.nes', '.zip', '.7z'];

List<String> get romFileTypeExtensions => [
  for (final extension in romPickerExtensions) extension.substring(1),
];
