import 'package:nes/exception/nesd_exception.dart';
import 'package:nes/extension/hex_extension.dart';

class InvalidOpcode extends NesdException {
  InvalidOpcode(int address, int opcode)
      : super(
          'Invalid opcode 0x${opcode.toHex()} at 0x${address.toHex(4)}',
        );
}
