import 'dart:typed_data';

class PPU {
  final Uint8List registers = Uint8List(8);
  final Uint8List ram = Uint8List(0x0800);

  int read(int address) {
    return 0;
  }

  void write(int address, int value) {}

  void step() {}
}
