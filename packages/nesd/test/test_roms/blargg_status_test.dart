import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

const _passing = <String>[
  'instr_test-v5/all_instrs.nes',
  'instr_timing/instr_timing.nes',
  'instr_misc/rom_singles/01-abs_x_wrap.nes',
  'instr_misc/rom_singles/02-branch_wrap.nes',
  'cpu_interrupts_v2/rom_singles/1-cli_latency.nes',
  'cpu_exec_space/test_cpu_exec_space_apu.nes',
  'cpu_exec_space/test_cpu_exec_space_ppuio.nes',
  'ppu_open_bus/ppu_open_bus.nes',
  'cpu_dummy_writes/cpu_dummy_writes_oam.nes',
  'cpu_dummy_writes/cpu_dummy_writes_ppumem.nes',
  'apu_test/rom_singles/1-len_ctr.nes',
  'apu_test/rom_singles/2-len_table.nes',
  'apu_test/rom_singles/3-irq_flag.nes',
  'apu_test/rom_singles/7-dmc_basics.nes',
  'mmc3_test/1-clocking.nes',
  'mmc3_test/2-details.nes',
  'mmc3_test/3-A12_clocking.nes',
  'mmc3_test/5-MMC3.nes',
  'oam_read/oam_read.nes',
  'oam_stress/oam_stress.nes',
  'ppu_vbl_nmi/rom_singles/01-vbl_basics.nes',
  'ppu_vbl_nmi/rom_singles/03-vbl_clear_time.nes',
  'ppu_vbl_nmi/rom_singles/09-even_odd_frames.nes',
  'ppu_vbl_nmi/rom_singles/10-even_odd_timing.nes',
];

/// known failing ROMs and the error code they report
const _knownFailures = <String, int>{
  // Needs the NMI to be serviced after the instruction following the
  // $2000 write. The 6502 polls for interrupts on an instruction's
  // second-to-last cycle.
  'ppu_vbl_nmi/rom_singles/04-nmi_control.nes': 11,
};

void main() {
  group('passing', () {
    for (final rom in _passing) {
      test(rom, () {
        final result = RomRobot('$_base/$rom').runUntilResult();

        expect(result.passed, isTrue, reason: result.toString());
      });
    }
  });

  group('known failures', () {
    for (final entry in _knownFailures.entries) {
      test(entry.key, () {
        final result = RomRobot('$_base/${entry.key}').runUntilResult();

        expect(result.status, equals(entry.value), reason: result.toString());
      });
    }
  });
}
