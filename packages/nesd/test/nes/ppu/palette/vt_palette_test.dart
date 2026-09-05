import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/vt_palette.dart';

const _golden = {
  0x000: 0xff000000, // S=0 L=0 H=0: black
  0x0f0: 0xffffffff, // S=0 L=F H=0: white
  0x080: 0xff696969, // S=0 L=8 H=0: mid gray
  0x0f1: 0xffffffff, // S=0 L=F H=1: hues are gray at S=0
  0x774: 0xffd20aa4, // mid saturation purple
  0x078: 0xff4f4f4f, // S=0 L=7 H=8: gray
  0x0fd: 0xffffffff, // S=0 L=F H=D: lower bound gray, bright
  0xf01: 0xff566775, // inverted: L=0 at S=F
  0xf84: 0xffff00ff, // S=F L=8: the one non-inverted row at S=F
  0xff2: 0xff335253, // inverted: L=F at S=F
  0x8fc: 0xff041fc9, // inverted: original hue C keeps phase offset 0
  0x77d: 0xff000000, // dark gray bound clamps to black
  0xb16: 0xffa7a536, // inverted low-side mid color
  0x3f5: 0xff00c900, // saturated green
};

void main() {
  group('vtPalette', () {
    test('has one entry per 12-bit color number', () {
      expect(vtPalette.length, 0x1000);
    });

    test('matches the reference decode for known entries', () {
      for (final MapEntry(key: value, value: expected) in _golden.entries) {
        expect(
          vtPalette[value],
          expected,
          reason: 'entry 0x${value.toRadixString(16)}',
        );
      }
    });

    test('every entry is opaque', () {
      for (var i = 0; i < 0x1000; i++) {
        expect(vtPalette[i] >>> 24, 0xff, reason: 'entry $i');
      }
    });

    test('hues 14 and 15 are black at every saturation and luminance', () {
      for (var sl = 0; sl < 0x100; sl++) {
        expect(vtPalette[(sl << 4) | 0xe], 0xff000000);
        expect(vtPalette[(sl << 4) | 0xf], 0xff000000);
      }
    });

    test('hues 0 and 13 are gray at every saturation and luminance', () {
      for (var sl = 0; sl < 0x100; sl++) {
        for (final hue in [0x0, 0xd]) {
          final entry = vtPalette[(sl << 4) | hue];

          final r = entry & 0xff;
          final g = (entry >> 8) & 0xff;
          final b = (entry >> 16) & 0xff;

          expect(r, g, reason: 'entry ${(sl << 4) | hue}');
          expect(g, b, reason: 'entry ${(sl << 4) | hue}');
        }
      }
    });

    test('all hues are gray at saturation 0', () {
      for (var luma = 0; luma < 0x10; luma++) {
        for (var hue = 1; hue <= 12; hue++) {
          final entry = vtPalette[(luma << 4) | hue];

          final r = entry & 0xff;
          final g = (entry >> 8) & 0xff;
          final b = (entry >> 16) & 0xff;

          expect(r, g, reason: 'luma $luma hue $hue');
          expect(g, b, reason: 'luma $luma hue $hue');
        }
      }
    });
  });
}
