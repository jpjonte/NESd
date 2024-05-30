import 'dart:typed_data';

import 'package:nes/exception/nesd_exception.dart';

class InvalidRomHeader extends NesdException {
  InvalidRomHeader(Uint8List header)
      : super('Invalid ROM: Expected "NES" at 0x00-0x03,'
            ' got ${header[0]}${header[1]}${header[2]}');
}
