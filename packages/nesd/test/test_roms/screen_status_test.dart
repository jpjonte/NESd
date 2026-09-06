import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/region.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

/// Test ROMs that only report on screen.
const _passing = <String>[
  'vbl_nmi_timing/1.frame_basics.nes',
  'vbl_nmi_timing/2.vbl_timing.nes',
  'vbl_nmi_timing/3.even_odd_frames.nes',
  'vbl_nmi_timing/4.vbl_clear_timing.nes',
  'vbl_nmi_timing/5.nmi_suppression.nes',
  'vbl_nmi_timing/6.nmi_disable.nes',
  'vbl_nmi_timing/7.nmi_timing.nes',
  'sprite_overflow_tests/1.Basics.nes',
  'sprite_overflow_tests/2.Details.nes',
  'sprite_overflow_tests/3.Timing.nes',
  'sprite_overflow_tests/4.Obscure.nes',
  'sprite_overflow_tests/5.Emulator.nes',
  'cpu_dummy_reads/cpu_dummy_reads.nes',
  'branch_timing_tests/1.Branch_Basics.nes',
  'branch_timing_tests/2.Backward_Branch.nes',
  'branch_timing_tests/3.Forward_Branch.nes',
  'dmc_dma_during_read4/dma_2007_write.nes',
  'dmc_dma_during_read4/read_write_2007.nes',
  'dmc_dma_during_read4/dma_4016_read.nes',
  'blargg_ppu_tests_2005.09.15b/palette_ram.nes',
  'blargg_ppu_tests_2005.09.15b/sprite_ram.nes',
  'blargg_ppu_tests_2005.09.15b/vbl_clear_time.nes',
  'blargg_ppu_tests_2005.09.15b/vram_access.nes',
  'blargg_apu_2005.07.30/01.len_ctr.nes',
  'blargg_apu_2005.07.30/02.len_table.nes',
  'blargg_apu_2005.07.30/03.irq_flag.nes',
  'blargg_apu_2005.07.30/04.clock_jitter.nes',
  'blargg_apu_2005.07.30/05.len_timing_mode0.nes',
  'blargg_apu_2005.07.30/06.len_timing_mode1.nes',
  'blargg_apu_2005.07.30/07.irq_flag_timing.nes',
  'blargg_apu_2005.07.30/08.irq_timing.nes',
  'blargg_apu_2005.07.30/09.reset_timing.nes',
  'blargg_apu_2005.07.30/10.len_halt_timing.nes',
  'blargg_apu_2005.07.30/11.len_reload_timing.nes',
];

const _passingPal = <String>[
  'pal_apu_tests/01.len_ctr.nes',
  'pal_apu_tests/02.len_table.nes',
  'pal_apu_tests/03.irq_flag.nes',
  'pal_apu_tests/04.clock_jitter.nes',
  'pal_apu_tests/05.len_timing_mode0.nes',
  'pal_apu_tests/06.len_timing_mode1.nes',
  'pal_apu_tests/07.irq_flag_timing.nes',
  'pal_apu_tests/08.irq_timing.nes',
  'pal_apu_tests/10.len_halt_timing.nes',
  'pal_apu_tests/11.len_reload_timing.nes',
];

/// known failing ROMs and the failure code they draw
const _knownFailures = <String, int>{
  // palette differs from the table of one particular console
  'blargg_ppu_tests_2005.09.15b/power_up_palette.nes': 2,
};

const _expectedCrcs = <String, Set<String>>{
  'dmc_dma_during_read4/dma_2007_read.nes': {'159A7A8F', '5E3DF9C4'},
};

void main() {
  group('passing', () {
    for (final rom in _passing) {
      test(rom, () {
        final result = RomRobot('$_base/$rom').runUntilScreenResult();

        expect(result.passed, isTrue, reason: result.toString());
      });
    }
  });

  group('passing on PAL', () {
    for (final rom in _passingPal) {
      test(rom, () {
        final result = RomRobot(
          '$_base/$rom',
          region: Region.pal,
        ).runUntilScreenResult();

        expect(result.passed, isTrue, reason: result.toString());
      });
    }
  });

  group('known failures', () {
    for (final entry in _knownFailures.entries) {
      test(entry.key, () {
        final result = RomRobot('$_base/${entry.key}').runUntilScreenResult();

        expect(result.status, equals(entry.value), reason: result.toString());
      });
    }
  });

  group('expected CRC', () {
    for (final entry in _expectedCrcs.entries) {
      test(entry.key, () {
        final robot = RomRobot('$_base/${entry.key}');
        final crc = robot.runUntilScreenCrc();

        expect(
          entry.value,
          contains(crc),
          reason: 'screen: ${robot.screenText().trim()}',
        );
      });
    }
  });
}
