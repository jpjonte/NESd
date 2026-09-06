import 'package:flutter_test/flutter_test.dart';

import '../../tool/test_rom_table.dart';

const _statusSource = '''
const _base = '../../roms/test';

const _passing = <String>[
  'instr_test-v5/all_instrs.nes',
  'apu_test/rom_singles/1-len_ctr.nes',
  'apu_test/rom_singles/2-len_table.nes',
];

/// known failing ROMs and the error code they report
const _knownFailures = <String, int>{
  'mmc3_test/6-MMC6.nes': 2,
};
''';

const _goldenSource = r'''
const _goldens = <String, int>{
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/01.basics.nes': -1967687481555138660,
  // change detector only
  '$_base/scanline/scanline.nes': -5071674518877676179,
};
''';

const _robotSource = '''
    RomRobot('../../roms/test/nestest/nestest.nes').runUntil(
''';

String _readme({
  String summary = '0 of 0 test ROMs run in CI and pass.',
  List<String> rows = const [
    '| CPU | `instr_test-v5` | blargg | 0 / 1 | all 16 sub-tests |',
    '| APU | `apu_test` | blargg | 0 / 8 | |',
    '| Mapper | `mmc3_test` | blargg | 0 / 6 | 6-MMC6 tests the MMC6 |',
  ],
}) =>
    '''
# NESd

## Accuracy

<!-- test-roms:start -->

$summary

<details>
<summary>Test ROM results</summary>

| Area | Suite | Author | Passing | Notes |
|------|-------|--------|---------|-------|
${rows.join('\n')}

</details>

<!-- test-roms:end -->

## Next section
''';

void main() {
  group('TestRomCoverage.fromSources', () {
    test('collects ROM paths in every spelling the tests use', () {
      final coverage = TestRomCoverage.fromSources([
        _statusSource,
        _goldenSource,
        _robotSource,
      ]);

      expect(coverage.passing, {
        'instr_test-v5/all_instrs.nes',
        'apu_test/rom_singles/1-len_ctr.nes',
        'apu_test/rom_singles/2-len_table.nes',
        'sprite_hit_tests_2005.10.05/01.basics.nes',
        'scanline/scanline.nes',
        'nestest/nestest.nes',
      });
    });

    test('lists _knownFailures entries as failing, not passing', () {
      final coverage = TestRomCoverage.fromSources([_statusSource]);

      expect(coverage.failing, {'mmc3_test/6-MMC6.nes'});
      expect(coverage.passing, isNot(contains('mmc3_test/6-MMC6.nes')));
    });

    test('counts a ROM once when several tests run it', () {
      final coverage = TestRomCoverage.fromSources([
        _robotSource,
        _robotSource,
      ]);

      expect(coverage.passing, hasLength(1));
    });

    test('counts passing ROMs per suite, including suites that only fail', () {
      final coverage = TestRomCoverage.fromSources([_statusSource]);

      expect(coverage.suites, {'instr_test-v5', 'apu_test', 'mmc3_test'});
      expect(coverage.passingIn('apu_test'), 2);
      expect(coverage.passingIn('mmc3_test'), 0);
    });
  });

  group('updateTestRomTable', () {
    final coverage = TestRomCoverage.fromSources([_statusSource]);

    test('rewrites only the row counts and the summary', () {
      final updated = updateTestRomTable(_readme(), coverage);

      expect(
        updated,
        _readme(
          summary: '3 of 15 test ROMs run in CI and pass.',
          rows: [
            '| CPU | `instr_test-v5` | blargg | 1 / 1 | all 16 sub-tests |',
            '| APU | `apu_test` | blargg | 2 / 8 | |',
            '| Mapper | `mmc3_test` | blargg | 0 / 6 | 6-MMC6 tests the MMC6 |',
          ],
        ),
      );
    });

    test('says all ROMs pass when every ROM in the table runs and passes', () {
      final passingOnly = TestRomCoverage.fromSources([_goldenSource]);
      final readme = _readme(
        rows: [
          '| PPU | `sprite_hit_tests_2005.10.05` | blargg | 0 / 1 | |',
          '| PPU | `scanline` | Quietust | 0 / 1 | framebuffer golden |',
        ],
      );

      final updated = updateTestRomTable(readme, passingOnly);

      expect(updated, contains('All 2 test ROMs run in CI and pass.'));
    });

    test('is idempotent', () {
      final updated = updateTestRomTable(_readme(), coverage);

      expect(updateTestRomTable(updated, coverage), updated);
    });

    test('rejects a suite without a table row', () {
      final readme = _readme(
        rows: [
          '| CPU | `instr_test-v5` | blargg | 0 / 1 | |',
          '| APU | `apu_test` | blargg | 0 / 8 | |',
        ],
      );

      expect(
        () => updateTestRomTable(readme, coverage),
        throwsA(_formatExceptionMentioning('mmc3_test')),
      );
    });

    test('rejects a table row without any ROM in the tests', () {
      final readme = _readme(
        rows: [
          '| CPU | `instr_test-v5` | blargg | 0 / 1 | |',
          '| APU | `apu_test` | blargg | 0 / 8 | |',
          '| Mapper | `mmc3_test` | blargg | 0 / 6 | |',
          '| PPU | `ppu_vbl_nmi` | blargg | 0 / 10 | |',
        ],
      );

      expect(
        () => updateTestRomTable(readme, coverage),
        throwsA(_formatExceptionMentioning('ppu_vbl_nmi')),
      );
    });

    test('rejects a row whose total is below the passing count', () {
      final readme = _readme(
        rows: [
          '| CPU | `instr_test-v5` | blargg | 0 / 1 | |',
          '| APU | `apu_test` | blargg | 0 / 1 | |',
          '| Mapper | `mmc3_test` | blargg | 0 / 6 | |',
        ],
      );

      expect(
        () => updateTestRomTable(readme, coverage),
        throwsA(_formatExceptionMentioning('apu_test')),
      );
    });

    test('rejects a README without the markers', () {
      expect(
        () => updateTestRomTable('# NESd\n', coverage),
        throwsA(_formatExceptionMentioning('test-roms:start')),
      );
    });
  });
}

Matcher _formatExceptionMentioning(String text) => isA<FormatException>()
    .having((exception) => exception.message, 'message', contains(text));
