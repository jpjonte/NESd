import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/input_device.dart';

class Controller implements InputDevice {
  int _shift = 0;
  int _status = 0;

  bool _strobe = false;

  @override
  int read(int address, {bool disableSideEffects = false}) {
    final value = _shift >= 8 ? 1 : (_status >> _shift) & 1;

    if (!_strobe && !disableSideEffects) {
      _shift++;
    }

    return value;
  }

  @override
  void write(int address, int value) {
    _strobe = (value & 1) == 1;
    _shift = 0;
  }

  void buttonDown(NesButton button) {
    _status |= 1 << button.index;
  }

  void buttonUp(NesButton button) {
    _status &= ~(1 << button.index);
  }

  void buttonToggle(NesButton button) {
    if (_status & (1 << button.index) == 0) {
      buttonDown(button);
    } else {
      buttonUp(button);
    }
  }
}
