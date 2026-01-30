import 'package:nesd/exception/nesd_exception.dart';

class UnsupportedFileType extends NesdException {
  UnsupportedFileType(String extension)
    : super('Unsupported file type: $extension');
}
