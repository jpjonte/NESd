import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/unit/length_counter_unit.dart';

// Register writes reach the length counter one CPU cycle late: the frame
// counter step of the cycle after the write still sees the old halt flag,
// and a reload written in that cycle loses against a decrement in that
// step (blargg_apu_2005 10.len_halt_timing and 11.len_reload_timing).
void main() {
  group('LengthCounterUnit', () {
    test('a halt written before a step does not stop that step', () {
      final unit = LengthCounterUnit()
        ..value = 2
        ..pendingHalt = true
        ..step();

      expect(unit.value, 1);
      expect(unit.halt, isFalse);
    });

    test('a halt takes effect once the pending writes are applied', () {
      final unit = LengthCounterUnit()
        ..value = 2
        ..pendingHalt = true
        ..applyPendingWrites()
        ..step();

      expect(unit.value, 2);
      expect(unit.halt, isTrue);
    });

    test('clearing the halt is delayed the same way', () {
      final unit = LengthCounterUnit()
        ..value = 2
        ..halt = true
        ..pendingHalt = false
        ..step();

      expect(unit.value, 2);

      unit
        ..applyPendingWrites()
        ..step();

      expect(unit.value, 1);
    });

    test('a reload is dropped when the next step decrements', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..writeValue(2)
        ..step()
        ..applyPendingWrites();

      expect(unit.value, 5);
    });

    test('a reload is kept when the counter was zero at the step', () {
      final unit = LengthCounterUnit()
        ..value = 0
        ..writeValue(2)
        ..step()
        ..applyPendingWrites();

      expect(unit.value, 2);
    });

    test('a reload is kept when the counter was halted at the step', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..halt = true
        ..writeValue(2)
        ..step()
        ..applyPendingWrites();

      expect(unit.value, 2);
    });

    test('a reload without a step in between applies', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..writeValue(2)
        ..applyPendingWrites();

      expect(unit.value, 2);
    });

    test('a decrement before the write does not drop the reload', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..step()
        ..writeValue(2)
        ..applyPendingWrites();

      expect(unit.value, 2);
    });

    test('applying twice does not re-apply a consumed write', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..writeValue(2)
        ..applyPendingWrites()
        ..step()
        ..applyPendingWrites();

      expect(unit.value, 1);
    });

    test('pending writes survive a state round trip', () {
      final unit = LengthCounterUnit()
        ..value = 6
        ..pendingHalt = true
        ..writeValue(2);

      final restored = LengthCounterUnit()
        ..state = unit.state
        ..applyPendingWrites();

      expect(restored.value, 2);
      expect(restored.halt, isTrue);
    });
  });
}
