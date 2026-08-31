import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

const _passing = <String>[
  'instr_test-v5/all_instrs.nes',
  'instr_timing/instr_timing.nes',
  'instr_misc/rom_singles/01-abs_x_wrap.nes',
  'instr_misc/rom_singles/02-branch_wrap.nes',
  'cpu_interrupts_v2/rom_singles/1-cli_latency.nes',
  'mmc3_test/1-clocking.nes',
  'mmc3_test/5-MMC3.nes',
  'ppu_vbl_nmi/rom_singles/01-vbl_basics.nes',
  'ppu_vbl_nmi/rom_singles/09-even_odd_frames.nes',
];

void main() {
  for (final rom in _passing) {
    test(rom, () {
      final result = RomRobot('$_base/$rom').runUntilResult();

      expect(result.passed, isTrue, reason: result.toString());
    });
  }

  test('cpu_dummy_writes_oam reaches a verdict without crashing', () {
    final result = RomRobot(
      '$_base/cpu_dummy_writes/cpu_dummy_writes_oam.nes',
    ).runUntilResult();

    expect(result.status, isNot(equals(0)), reason: result.toString());
  });
}
