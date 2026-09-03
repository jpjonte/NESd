import 'package:nesd/exception/nesd_exception.dart';

class InvalidArchive extends NesdException {
  InvalidArchive(String path, {String? reason, super.previous})
    : super(
        reason == null
            ? 'Archive $path could not be read.'
            : 'Archive $path could not be read: $reason',
      );
}
