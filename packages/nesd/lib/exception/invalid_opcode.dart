import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/extension/hex_extension.dart';

class InvalidOpcode extends NesdException {
  InvalidOpcode(int address, int opcode)
    : super(
        'Invalid opcode ${opcode.toHex()}'
        ' at ${address.toHex(width: 4, prefix: true)}',
      );
}
