import 'package:nesd/extension/bit_extension.dart';

class A12EdgeDetector {
  int lowStart = 0;

  bool detect(int address, int cycles) {
    if (address.bit(12) == 1) {
      // in our implementation, the NT/AT fetch low at the end of a scanline
      // measures exactly 3 CPU cycles -> require at least 4 low cycles
      final cyclesHaveElapsed = lowStart > 0 && (cycles - lowStart) >= 4;

      lowStart = 0;

      return cyclesHaveElapsed;
    }

    if (lowStart == 0) {
      lowStart = cycles;
    }

    return false;
  }
}
