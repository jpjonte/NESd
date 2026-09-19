import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/input/input_device.dart';

class Controller implements InputDevice {
  int _shift = 0;
  int _status = 0;
  int _turbo = 0;

  bool _strobe = false;

  int _shiftBeforeWrite = 0;
  bool _strobeBeforeWrite = false;

  bool turboPhase = true;

  int get _output => turboPhase ? _status | _turbo : _status;

  @override
  int read(int address, {bool disableSideEffects = false}) {
    final value = _shift >= 8 ? 1 : (_output >> _shift) & 1;

    if (!_strobe && !disableSideEffects) {
      _shift++;
    }

    return value;
  }

  @override
  void write(int address, int value) {
    _shiftBeforeWrite = _shift;
    _strobeBeforeWrite = _strobe;

    _strobe = (value & 1) == 1;

    if (_strobe) {
      _shift = 0;
    }
  }

  @override
  void revertWrite() {
    _shift = _shiftBeforeWrite;
    _strobe = _strobeBeforeWrite;
  }

  void buttonDown(NesButton button, {bool turbo = false}) {
    if (turbo) {
      _turbo |= 1 << button.index;
    } else {
      _status |= 1 << button.index;
    }
  }

  void buttonUp(NesButton button, {bool turbo = false}) {
    if (turbo) {
      _turbo &= ~(1 << button.index);
    } else {
      _status &= ~(1 << button.index);
    }
  }

  void buttonToggle(NesButton button, {bool turbo = false}) {
    final mask = turbo ? _turbo : _status;

    if (mask & (1 << button.index) == 0) {
      buttonDown(button, turbo: turbo);
    } else {
      buttonUp(button, turbo: turbo);
    }
  }
}
