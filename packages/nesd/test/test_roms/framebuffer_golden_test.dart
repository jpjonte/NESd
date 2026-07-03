import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

// Golden framebuffer hashes captured from the current implementation.
// Any core change that alters rendered output for these deterministic,
// input-free ROMs will change a hash and fail this test.
//
// Each sprite-hit ROM renders its PASS/FAILED verdict on screen (zero
// page $f8: 1 = passed, other values = failure code), so the hash below
// also encodes the current accuracy verdict for that ROM. The verdict
// comment reflects the state as of this capture; it is not re-derived
// by this test.
const _goldens = <String, int>{
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/01.basics.nes': -1967687481555138660,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/02.alignment.nes': -3573559364309911299,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/03.corners.nes': -4262848908335653659,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/04.flip.nes': 5904881314694705061,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/05.left_clip.nes': 5206097848173752517,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/06.right_edge.nes': -5911235697103760443,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/07.screen_bottom.nes': 180010584670853700,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/08.double_height.nes':
      -4246198069118455891,
  // FAILED #9: cleared at end of VBL too late
  '$_base/sprite_hit_tests_2005.10.05/09.timing_basics.nes':
      -8469869588937526515,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/10.timing_order.nes':
      -5712493370050576132,
  // PASSED
  '$_base/sprite_hit_tests_2005.10.05/11.edge_timing.nes': 8772810262352546524,
  '$_base/scanline/scanline.nes': -3956729394634635011,
  '$_base/spritecans-2011/spritecans.nes': 6027694824722942956,
  '$_base/full_palette/full_palette.nes': 6387691627853472549,
};

void main() {
  for (final entry in _goldens.entries) {
    test('framebuffer golden: ${entry.key.split('/').last}', () {
      final robot = RomRobot(entry.key)..runFrames(360);

      final hash = robot.framebufferHash();

      expect(
        hash,
        equals(entry.value),
        reason: 'actual hash for ${entry.key}: $hash',
      );
    });
  }
}
