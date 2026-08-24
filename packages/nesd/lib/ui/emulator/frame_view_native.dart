import 'dart:ffi';
import 'dart:typed_data';

Uint8List frameBytesFromAddress(int address, int length) =>
    Pointer<Uint8>.fromAddress(address).asTypedList(length);
