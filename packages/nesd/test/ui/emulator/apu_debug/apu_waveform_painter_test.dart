import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_waveform_painter.dart';

void main() {
  group('findTriggerIndex', () {
    test('returns 0 for fewer than 2 samples', () {
      expect(findTriggerIndex(const []), 0);
      expect(findTriggerIndex(const [5]), 0);
    });

    test('returns 0 for a flat signal', () {
      expect(findTriggerIndex(const [7, 7, 7, 7, 7, 7, 7, 7]), 0);
    });

    test('finds the first rising edge across the midpoint', () {
      // Midpoint is 7.5; first rise from below to >= 7.5 is at index 2.
      const square = [0, 0, 15, 15, 0, 0, 15, 15, 0, 0, 15, 15, 0, 0, 15, 15];

      expect(findTriggerIndex(square), 2);
    });

    test('returns 0 when the first rising edge is past the first '
        'quarter', () {
      // 16 samples; search stops at index 4; the edge is at index 8.
      const late = [15, 15, 15, 15, 0, 0, 0, 0, 15, 15, 15, 15, 0, 0, 0, 0];

      expect(findTriggerIndex(late), 0);
    });
  });
}
