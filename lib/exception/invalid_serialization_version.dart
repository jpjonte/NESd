import 'package:nesd/exception/nesd_exception.dart';

class InvalidSerializationVersion extends NesdException {
  InvalidSerializationVersion(String component, int version)
    : super(
        'Invalid serialization version $version'
        ' for $component',
      );
}
