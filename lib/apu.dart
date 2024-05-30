import 'package:nes/bus.dart';

class APU {
  APU(this.bus);

  final Bus bus;

  int status = 0;

  void reset() {}

  int read(int address) => bus.apuRead(address);

  void write(int address, int value) => bus.apuWrite(address, value);
}
