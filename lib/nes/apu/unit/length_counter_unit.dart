class LengthCounterUnit {
  bool halt = false;

  int value = 0;

  void reset() {
    value = 0;
    halt = false;
  }

  void step() {
    if (!halt && value > 0) {
      value--;
    }
  }
}
