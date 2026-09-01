import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

/// VT03 OneBus. Minimal implementation until follow-up issues are implemented.
class Mapper256 extends VT02 {
  Mapper256([int subMapperId = 0]) : super(256, subMapperId);

  @override
  String get name => 'VT03 OneBus';
}
