import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

class LengthCounterUnit {
  bool halt = false;

  int value = 0;

  LengthCounterUnitState get state => LengthCounterUnitState(
        halt: halt,
        value: value,
      );

  set state(LengthCounterUnitState state) {
    halt = state.halt;
    value = state.value;
  }

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
