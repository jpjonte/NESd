import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/tile_debug_data.dart';

TileDebugData _build({
  Uint8List? ppuMemory,
  int ppuCtrl = 0,
  int v = 0,
  int t = 0,
  int x = 0,
}) => TileDebugData(
  ppuMemory: ppuMemory ?? Uint8List(0x4000),
  ppuCtrl: ppuCtrl,
  v: v,
  t: t,
  x: x,
);

void main() {
  group('TileDebugData', () {
    group('ppuRead', () {
      test('reads the byte at the given address', () {
        final memory = Uint8List(0x4000);
        memory[0x1234] = 0x42;

        final data = _build(ppuMemory: memory);

        expect(data.ppuRead(0x1234), 0x42);
      });

      test('masks the address to 0x3fff', () {
        final memory = Uint8List(0x4000);
        memory[0x0abc] = 0x99;

        final data = _build(ppuMemory: memory);

        // 0x4abc & 0x3fff == 0x0abc
        expect(data.ppuRead(0x4abc), 0x99);
      });
    });

    group('PPUCTRL_B', () {
      test('is 1 when ppuCtrl is 0xFF', () {
        expect(_build(ppuCtrl: 0xFF).PPUCTRL_B, 1);
      });

      test('is 0 when ppuCtrl is 0x00', () {
        expect(_build().PPUCTRL_B, 0);
      });

      test('reads only bit 4', () {
        expect(_build(ppuCtrl: 0x10).PPUCTRL_B, 1);
        expect(_build(ppuCtrl: 0xEF).PPUCTRL_B, 0);
      });
    });

    group('PPUCTRL_X', () {
      test('is 1 when ppuCtrl is 0xFF', () {
        expect(_build(ppuCtrl: 0xFF).PPUCTRL_X, 1);
      });

      test('is 0 when ppuCtrl is 0x00', () {
        expect(_build().PPUCTRL_X, 0);
      });

      test('reads only bit 0', () {
        expect(_build(ppuCtrl: 0x01).PPUCTRL_X, 1);
        expect(_build(ppuCtrl: 0xFE).PPUCTRL_X, 0);
      });
    });

    group('PPUCTRL_Y', () {
      test('is 1 when ppuCtrl is 0xFF', () {
        expect(_build(ppuCtrl: 0xFF).PPUCTRL_Y, 1);
      });

      test('is 0 when ppuCtrl is 0x00', () {
        expect(_build().PPUCTRL_Y, 0);
      });

      test('reads only bit 1', () {
        expect(_build(ppuCtrl: 0x02).PPUCTRL_Y, 1);
        expect(_build(ppuCtrl: 0xFD).PPUCTRL_Y, 0);
      });
    });

    group('t_coarseX', () {
      test('reads the low 5 bits of t', () {
        expect(_build(t: 0x1F).t_coarseX, 0x1F);
      });

      test('ignores bits outside the coarseX field', () {
        expect(_build(t: 0x7FE0).t_coarseX, 0);
      });
    });

    group('t_coarseY', () {
      test('reads bits 5-9 of t', () {
        expect(_build(t: 0x1F << 5).t_coarseY, 0x1F);
      });

      test('ignores bits outside the coarseY field', () {
        expect(_build(t: 0x7C1F).t_coarseY, 0);
      });
    });

    group('t_fineY', () {
      test('reads bits 12-14 of t', () {
        expect(_build(t: 0x7 << 12).t_fineY, 0x7);
      });

      test('ignores bits outside the fineY field', () {
        expect(_build(t: 0x0FFF).t_fineY, 0);
      });
    });

    test('decodes a combined t value into its three fields', () {
      // coarseX = 0x0A, coarseY = 0x15, fineY = 0x3
      const t = 0x0A | (0x15 << 5) | (0x3 << 12);

      final data = _build(t: t);

      expect(data.t_coarseX, 0x0A);
      expect(data.t_coarseY, 0x15);
      expect(data.t_fineY, 0x3);
    });
  });
}
