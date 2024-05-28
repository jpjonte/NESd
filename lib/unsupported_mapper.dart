import 'package:nes/nesd_exception.dart';

class UnsupportedMapper extends NesdException {
  UnsupportedMapper(int mapperId, int subMapperId)
      : super('Unsupported mapper: $mapperId, submapper: $subMapperId');
}
