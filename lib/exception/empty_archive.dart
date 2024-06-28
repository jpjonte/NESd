import 'package:nes/exception/nesd_exception.dart';

class EmptyArchive extends NesdException {
  EmptyArchive(String path)
      : super('Archive $path does not contain a NES ROM.');
}
