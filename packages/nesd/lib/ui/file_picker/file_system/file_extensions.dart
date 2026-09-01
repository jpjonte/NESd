import 'package:path/path.dart' as p;

String fileExtension(String path) => p.extension(path).toLowerCase();

bool isRomFile(String path) => fileExtension(path) == '.nes';

bool isZipFile(String path) => fileExtension(path) == '.zip';
