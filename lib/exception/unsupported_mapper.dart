import 'package:nes/exception/nesd_exception.dart';

class UnsupportedMapper extends NesdException {
  UnsupportedMapper(int mapperId, int subMapperId)
      : super('Unsupported mapper: $mapperId, submapper: $subMapperId');
}
