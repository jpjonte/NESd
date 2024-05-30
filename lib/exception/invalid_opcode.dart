import 'package:nes/exception/nesd_exception.dart';

class InvalidOpcode extends NesdException {
  InvalidOpcode(int address, int opcode)
      : super(
          'Invalid opcode 0x${opcode.toRadixString(16)}'
          ' at 0x${address.toRadixString(16)}',
        );
}
