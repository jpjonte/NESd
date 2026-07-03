import 'package:flutter_test/flutter_test.dart';

import 'rom_robot.dart';

const _base = '../../roms/test';

// Golden framebuffer hashes captured from the current implementation.
// Any core change that alters rendered output for these deterministic,
// input-free ROMs will change a hash and fail this test.
const _goldens = <String, int>{
  '$_base/sprite_hit_tests_2005.10.05/01.basics.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/02.alignment.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/03.corners.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/04.flip.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/05.left_clip.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/06.right_edge.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/07.screen_bottom.nes':
      1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/08.double_height.nes':
      1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/09.timing_basics.nes':
      1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/10.timing_order.nes': 1664604141990159141,
  '$_base/sprite_hit_tests_2005.10.05/11.edge_timing.nes': 1664604141990159141,
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
