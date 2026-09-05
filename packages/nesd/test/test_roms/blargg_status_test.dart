import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

const _passing = <String>[
  'instr_test-v5/all_instrs.nes',
  'instr_timing/instr_timing.nes',
  'instr_misc/rom_singles/01-abs_x_wrap.nes',
  'instr_misc/rom_singles/02-branch_wrap.nes',
  'instr_misc/rom_singles/03-dummy_reads.nes',
  'instr_misc/rom_singles/04-dummy_reads_apu.nes',
  'cpu_interrupts_v2/rom_singles/1-cli_latency.nes',
  'cpu_interrupts_v2/rom_singles/2-nmi_and_brk.nes',
  'cpu_interrupts_v2/rom_singles/3-nmi_and_irq.nes',
  'cpu_interrupts_v2/rom_singles/4-irq_and_dma.nes',
  'cpu_interrupts_v2/rom_singles/5-branch_delays_irq.nes',
  'cpu_exec_space/test_cpu_exec_space_apu.nes',
  'cpu_exec_space/test_cpu_exec_space_ppuio.nes',
  'ppu_open_bus/ppu_open_bus.nes',
  'sprdma_and_dmc_dma/sprdma_and_dmc_dma.nes',
  'sprdma_and_dmc_dma/sprdma_and_dmc_dma_512.nes',
  'cpu_dummy_writes/cpu_dummy_writes_oam.nes',
  'cpu_dummy_writes/cpu_dummy_writes_ppumem.nes',
  'apu_test/rom_singles/1-len_ctr.nes',
  'apu_test/rom_singles/2-len_table.nes',
  'apu_test/rom_singles/3-irq_flag.nes',
  'apu_test/rom_singles/4-jitter.nes',
  'apu_test/rom_singles/5-len_timing.nes',
  'apu_test/rom_singles/6-irq_flag_timing.nes',
  'apu_test/rom_singles/7-dmc_basics.nes',
  'apu_test/rom_singles/8-dmc_rates.nes',
  'mmc3_test/1-clocking.nes',
  'mmc3_test/2-details.nes',
  'mmc3_test/3-A12_clocking.nes',
  'mmc3_test/4-scanline_timing.nes',
  'mmc3_test/5-MMC3.nes',
  'mmc3_test_2/rom_singles/4-scanline_timing.nes',
  'oam_read/oam_read.nes',
  'oam_stress/oam_stress.nes',
  'ppu_vbl_nmi/rom_singles/01-vbl_basics.nes',
  'ppu_vbl_nmi/rom_singles/02-vbl_set_time.nes',
  'ppu_vbl_nmi/rom_singles/03-vbl_clear_time.nes',
  'ppu_vbl_nmi/rom_singles/04-nmi_control.nes',
  'ppu_vbl_nmi/rom_singles/05-nmi_timing.nes',
  'ppu_vbl_nmi/rom_singles/06-suppression.nes',
  'ppu_vbl_nmi/rom_singles/07-nmi_on_timing.nes',
  'ppu_vbl_nmi/rom_singles/08-nmi_off_timing.nes',
  'ppu_vbl_nmi/rom_singles/09-even_odd_frames.nes',
  'ppu_vbl_nmi/rom_singles/10-even_odd_timing.nes',
];

/// known failing ROMs and the error code they report
const _knownFailures = <String, int>{};

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
