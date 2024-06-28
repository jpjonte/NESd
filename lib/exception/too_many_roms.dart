import 'package:nes/exception/nesd_exception.dart';

class TooManyRoms extends NesdException {
  TooManyRoms(String path)
      : super('Archive $path contains more than one NES ROM.');
}
