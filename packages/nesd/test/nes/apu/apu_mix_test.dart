import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu_mix.dart';
import 'package:nesd/nes/apu/tables.dart';

void main() {
  group('pulseMix', () {
    test('reproduces every pulseTable entry exactly', () {
      for (var i = 0; i < pulseTable.length; i++) {
        expect(pulseMix(i.toDouble()), pulseTable[i], reason: 'index $i');
      }
    });

    test('follows the real curve between table entries, not a chord', () {
      final chord = pulseTable[0] + (pulseTable[1] - pulseTable[0]) * 0.5;
      final value = pulseMix(0.5);

      expect(value, greaterThan(pulseTable[0]));
      expect(value, lessThan(pulseTable[1]));

      expect(value, greaterThan(chord));
    });

    test('is silent at zero', () {
      expect(pulseMix(0), 0.0);
    });
  });

  group('tndMix', () {
    test('reproduces every tndTable entry exactly', () {
      for (var i = 0; i < tndTable.length; i++) {
        expect(tndMix(i.toDouble()), tndTable[i], reason: 'index $i');
      }
    });

    test('follows the real curve between table entries, not a chord', () {
      final chord = tndTable[0] + (tndTable[1] - tndTable[0]) * 0.5;
      final value = tndMix(0.5);

      expect(value, greaterThan(tndTable[0]));
      expect(value, lessThan(tndTable[1]));
      expect(value, greaterThan(chord));
    });

    test('is silent at zero', () {
      expect(tndMix(0), 0.0);
    });
  });

  test('both curves keep rising past the end of their tables', () {
    expect(pulseMix(60), greaterThan(pulseTable.last));
    expect(tndMix(400), greaterThan(tndTable.last));
  });
}
