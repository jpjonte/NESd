import 'package:nesd/nes/apu/unit/length_counter_unit_state.dart';

/// Register writes reach the counter one CPU cycle late: [pendingHalt] and
/// [writeValue] park the value until [applyPendingWrites] runs after the next
/// cycle's frame counter step, so that step still sees the old halt flag and
/// a reload loses against a decrement in it.
class LengthCounterUnit {
  bool halt = false;

  int value = 0;

  bool? pendingHalt;

  int? pendingValue;

  bool _decremented = false;

  LengthCounterUnitState get state => LengthCounterUnitState(
    halt: halt,
    value: value,
    pendingHalt: pendingHalt,
    pendingValue: pendingValue,
  );

  set state(LengthCounterUnitState state) {
    halt = state.halt;
    value = state.value;
    pendingHalt = state.pendingHalt;
    pendingValue = state.pendingValue;
    _decremented = false;
  }

  bool get hasPendingWrites => pendingHalt != null || pendingValue != null;

  void reset() {
    value = 0;
    halt = false;
    pendingHalt = null;
    pendingValue = null;
    _decremented = false;
  }

  void writeValue(int value) {
    pendingValue = value;
    _decremented = false;
  }

  void step() {
    if (!halt && value > 0) {
      value--;
      _decremented = true;
    }
  }

  void applyPendingWrites() {
    if (pendingHalt != null) {
      halt = pendingHalt!;
      pendingHalt = null;
    }

    if (pendingValue != null) {
      if (!_decremented) {
        value = pendingValue!;
      }

      pendingValue = null;
    }

    _decremented = false;
  }
}
