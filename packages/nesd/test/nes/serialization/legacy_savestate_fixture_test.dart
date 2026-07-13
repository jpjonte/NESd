import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/scanline/scanline.nes';

// Framebuffer hashes captured when the fixtures were generated on the
// pre-widening code (see test/fixtures/README.md). They pin migration
// behavior: loading a pre-widening save must keep replaying exactly like
// the build that wrote it, including the bug-for-bug window-rebuild
// semantics for the truncated pattern shift registers.
// _vblankHash and _midTileHash are intentionally the same integer: both
// fixtures replay to the same fully-repainted static frame two frames
// after loading, so the 2-frame endpoint does not distinguish the
// mid-tile restore path. The in-flight assertion below
// (_midTileInFlightHash), taken after only 1 frame from a mid-scanline
// restore, is what actually discriminates the window-rebuild
// reconstruction of the truncated pattern-shift registers.
const _vblankHash = 354463018454808845;
const _midTileInFlightHash = -5071674518877676179;
const _midTileHash = 354463018454808845;

void main() {
  test('pre-widening vblank fixture loads and replays identically', () {
    final bytes = File('test/fixtures/prewiden_vblank.state').readAsBytesSync();

    final robot = RomRobot(_romPath);

    robot.nes.state = NESState.fromBytes(bytes);

    robot.runFrames(2);

    expect(robot.framebufferHash(), _vblankHash);
  });

  test('pre-widening mid-tile fixture loads and replays identically', () {
    final bytes = File(
      'test/fixtures/prewiden_midtile.state',
    ).readAsBytesSync();

    final robot = RomRobot(_romPath);

    robot.nes.state = NESState.fromBytes(bytes);

    robot.runFrames(1);

    expect(robot.framebufferHash(), _midTileInFlightHash);

    robot.runFrames(1);

    expect(robot.framebufferHash(), _midTileHash);
  });
}
