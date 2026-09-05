import 'dart:typed_data';

Uint8List greyPalFile(int value) =>
    Uint8List(64 * 3)..fillRange(0, 64 * 3, value);
