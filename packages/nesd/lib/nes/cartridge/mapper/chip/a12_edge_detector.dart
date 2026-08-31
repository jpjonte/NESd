import 'package:nesd/extension/bit_extension.dart';

class A12EdgeDetector {
  int lowStart = 0;

  bool detect(int address, int cycles) {
    if (address.bit(12) == 1) {
      final cyclesHaveElapsed = lowStart > 0 && (cycles - lowStart) >= 3;

      lowStart = 0;

      return cyclesHaveElapsed;
    }

    if (lowStart == 0) {
      lowStart = cycles;
    }

    return false;
  }
}
