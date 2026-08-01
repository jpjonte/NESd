import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';

class Namco163Audio {
  Namco163Audio(this.subMapperId);

  final int subMapperId;

  final Uint8List ram = Uint8List(0x80);

  int address = 0;

  bool autoIncrement = false;

  void writeAddress(int value) {
    address = value & 0x7f;
    autoIncrement = value.bit(7) == 1;
  }

  void writeData(int value) {
    ram[address] = value;

    _advance();
  }

  int readData({bool disableSideEffects = false}) {
    final value = ram[address];

    if (!disableSideEffects) {
      _advance();
    }

    return value;
  }

  void reset() {
    ram.fillRange(0, ram.length, 0);

    address = 0;
    autoIncrement = false;
  }

  /// Auto-increment stops at `0x7f` instead of wrapping to `0x00`.
  void _advance() {
    if (autoIncrement && address < 0x7f) {
      address++;
    }
  }
}
