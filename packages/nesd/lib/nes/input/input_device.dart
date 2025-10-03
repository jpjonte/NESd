abstract class InputDevice {
  int read(int address, {bool disableSideEffects = false});

  void write(int address, int value);
}
