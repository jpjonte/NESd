import 'package:nesd/exception/nesd_exception.dart';

class UnsupportedMapper extends NesdException {
  UnsupportedMapper(int mapperId) : super('Unsupported mapper: $mapperId');
}
