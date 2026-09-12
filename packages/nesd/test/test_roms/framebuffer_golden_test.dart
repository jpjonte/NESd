import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

// Golden framebuffer hashes captured from the current implementation.
// Any core change that alters rendered output for these deterministic,
// input-free ROMs will change a hash and fail this test.

/// Test ROMs that draw a verdict: the hash pins the rendering and the
/// screen must read PASSED.
const _verdictGoldens = <String, int>{
  '$_base/sprite_hit_tests_2005.10.05/01.basics.nes': -1967687481555138660,
  '$_base/sprite_hit_tests_2005.10.05/02.alignment.nes': -3573559364309911299,
  '$_base/sprite_hit_tests_2005.10.05/03.corners.nes': -4262848908335653659,
  '$_base/sprite_hit_tests_2005.10.05/04.flip.nes': 5904881314694705061,
  '$_base/sprite_hit_tests_2005.10.05/05.left_clip.nes': 5206097848173752517,
  '$_base/sprite_hit_tests_2005.10.05/06.right_edge.nes': -5911235697103760443,
  '$_base/sprite_hit_tests_2005.10.05/07.screen_bottom.nes': 180010584670853700,
  '$_base/sprite_hit_tests_2005.10.05/08.double_height.nes':
      -4246198069118455891,
  '$_base/sprite_hit_tests_2005.10.05/09.timing_basics.nes':
      -5418624616629182540,
  '$_base/sprite_hit_tests_2005.10.05/10.timing_order.nes':
      -5712493370050576132,
  '$_base/sprite_hit_tests_2005.10.05/11.edge_timing.nes': 8772810262352546524,
};

/// Demos without a pass/fail verdict. The hash is a change detector only.
const _changeDetectors = <String, int>{
  // Mid-scanline write test.
  '$_base/scanline/scanline.nes': -5071674518877676179,
  '$_base/spritecans-2011/spritecans.nes': 6027694824722942956,
  '$_base/full_palette/full_palette.nes': 6387691627853472549,
  '$_base/mmc5test_v2/mmc5test.nes': 7390973552206513059,
  '$_base/m22chrbankingtest/0-127.nes': 536103781366711217,
};

void main() {
  for (final entry in _verdictGoldens.entries) {
    test('framebuffer golden: ${entry.key.split('/').last}', () {
      final robot = RomRobot(entry.key)..runFrames(360);

      _expectHash(robot, entry);

      final screen = robot.screenText();

      expect(
        RomResult.tryFromScreen(screen)?.passed,
        isTrue,
        reason: 'screen of ${entry.key}: ${screen.trim()}',
      );
    });
  }

  for (final entry in _changeDetectors.entries) {
    test('framebuffer golden: ${entry.key.split('/').last}', () {
      final robot = RomRobot(entry.key)..runFrames(360);

      _expectHash(robot, entry);
    });
  }
}

void _expectHash(RomRobot robot, MapEntry<String, int> entry) {
  final hash = robot.framebufferHash();

  expect(
    hash,
    equals(entry.value),
    reason: 'actual hash for ${entry.key}: $hash',
  );
}
