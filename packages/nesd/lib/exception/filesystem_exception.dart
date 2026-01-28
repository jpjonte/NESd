import 'package:nesd/exception/nesd_exception.dart';

class FilesystemException extends NesdException {
  FilesystemException({super.previous}) : super('Filesystem error: $previous');
}
