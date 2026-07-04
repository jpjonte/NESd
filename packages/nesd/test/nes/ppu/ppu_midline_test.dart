import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

import '../../test_roms/rom_robot.dart';

// Uses a committed golden ROM purely as a background-rendering vehicle;
// the assertions are about mid-scanline register semantics, not the
// ROM's own output. scanline.nes renders a full background.
const _romPath = '../../roms/test/scanline/scanline.nes';

/// Steps the NES until the PPU has reached (or passed) [scanline]:[cycle].
///
/// `stepTo` steps whole CPU instructions, each of which advances the PPU
/// by several dots, so landing on an exact dot is not guaranteed (odd
/// pre-render-scanline dot skips also shift the achievable landing dots
/// over time). Stopping at "reached or passed" keeps this robust while
/// still landing close enough to the target for the slack windows used
/// by the assertions below.
void stepTo(NES nes, int scanline, int cycle) {
  while (!_atOrPast(nes, scanline, cycle)) {
    nes.step();

    nes.apu.sampleIndex = 0;
  }
}

bool _atOrPast(NES nes, int scanline, int cycle) {
  final ppu = nes.ppu;

  if (ppu.scanline != scanline) {
    return false;
  }

  return ppu.cycle >= cycle;
}

/// Returns the row of pixels for scanline [y] of the current framebuffer.
List<int> _row(NES nes, int y) {
  final rowBase = y * 256;

  return List<int>.generate(
    256,
    (i) => nes.ppu.frameBuffer.pixels32[rowBase + i],
  );
}

/// Finds a visible scanline whose rendered row has at least two distinct
/// colors, so that a mid-scanline register change has visible pixels to
/// alter. Starts at row 120 (the brief's original choice) and searches
/// outward from there if that row happens to be uniform for this ROM.
int _findNonUniformRow(NES nes) {
  const preferred = 120;

  if (_row(nes, preferred).toSet().length >= 2) {
    return preferred;
  }

  for (var y = 0; y < 240; y++) {
    if (_row(nes, y).toSet().length >= 2) {
      return y;
    }
  }

  throw StateError('No non-uniform row found in framebuffer');
}

void main() {
  test('mid-scanline fine-x write shifts background pixels immediately', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;

    // Capture a reference scanline's pixels from the previous frame.
    final y = _findNonUniformRow(nes);
    final reference = _row(nes, y);

    // Advance to mid-row of scanline y in the next frame and change
    // fine-x via $2005 (first write; w toggles back on the second).
    stepTo(nes, y, 128);

    nes.bus.cpuWrite(0x2005, 0x04); // coarse 0, fine-x = 4
    nes.bus.cpuWrite(0x2005, 0x00); // second write completes the pair

    // Finish the scanline.
    while (nes.ppu.scanline == y) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }

    final after = _row(nes, y);

    // Pixels before the write dot are unaffected; at least one pixel
    // after it differs when the content is non-uniform (fine-x shifted
    // the mux within the same fetched tiles).
    expect(after.sublist(0, 120), reference.sublist(0, 120));
    expect(
      after.sublist(132),
      isNot(equals(reference.sublist(132))),
      reason: 'fine-x change mid-scanline must alter subsequent pixels',
    );
  });

  test('mid-scanline PPUMASK background disable blanks immediately', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;
    final y = _findNonUniformRow(nes);

    stepTo(nes, y, 128);

    final maskBefore = nes.ppu.PPUMASK;

    nes.bus.cpuWrite(0x2001, maskBefore & ~0x08); // bg off

    while (nes.ppu.scanline == y) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }

    nes.bus.cpuWrite(0x2001, maskBefore); // restore

    // After the disable dot, background pixels render as color 0
    // (the backdrop). All post-write pixels must be identical to each
    // other (uniform backdrop) — allow a few dots of write latency
    // between the CPU write and the PPU dot it lands on.
    final row = _row(nes, y);
    final tail = row.sublist(140);

    expect(
      tail.toSet().length,
      1,
      reason: 'disabled background must render uniform backdrop',
    );
  });

  test('savestate round trip mid-scanline continues byte-identically', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;

    stepTo(nes, 120, 100); // mid-scanline, mid-tile

    final state = nes.state!.serialize();

    // Continue 2 frames on the original.
    robot.runFrames(2);

    final expected = robot.framebufferHash();

    // Restore into a fresh NES and continue identically.
    final robot2 = RomRobot(_romPath);

    robot2.nes.state = NESState.fromBytes(state);

    robot2.runFrames(2);

    expect(robot2.framebufferHash(), expected);
  });
}
