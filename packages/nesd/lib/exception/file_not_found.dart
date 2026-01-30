import 'package:nesd/exception/nesd_exception.dart';

class FileNotFound extends NesdException {
  FileNotFound({required String path, super.previous})
    : super('Could not find $path');
}
