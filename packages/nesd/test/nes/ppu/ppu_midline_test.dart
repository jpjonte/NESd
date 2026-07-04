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

/// Writes [values] to PPU memory at [address] via $2006/$2007, the way
/// a program would during vblank. Leaves `w` at 0 (two $2006 writes).
void _writeVram(NES nes, int address, List<int> values) {
  nes.bus.cpuWrite(0x2006, (address >> 8) & 0x3f);
  nes.bus.cpuWrite(0x2006, address & 0xff);

  for (final value in values) {
    nes.bus.cpuWrite(0x2007, value);
  }
}

/// Runs [robot] to the end of the frame currently in flight.
void _finishFrame(RomRobot robot) {
  final nes = robot.nes;
  final frame = nes.ppu.frames;

  while (nes.ppu.frames == frame) {
    nes.step();

    nes.apu.sampleIndex = 0;
  }
}

/// Finds a background tile whose top row is opaque at pixels 1 and 2,
/// so a mid-tile save always has visibly colored next-tile pixels.
int _findTextTile(NES nes) {
  for (var tile = 1; tile < 256; tile++) {
    final base = 0x1000 | (tile << 4);
    final low = nes.ppu.readPpuMemory(base, updateBusAddress: false);
    final high = nes.ppu.readPpuMemory(base | 8, updateBusAddress: false);

    if (((low | high) & 0x60) == 0x60) {
      return tile;
    }
  }

  throw StateError('no suitable tile found in CHR');
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

  test('savestate round trip at a reload boundary continues '
      'byte-identically', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;

    // Land on a background reload dot (cycle & 7 == 0), where the pixel
    // window has just slid and _bgWindowPos is (near) zero.
    stepTo(nes, 120, 96);

    final state = nes.state!.serialize();

    robot.runFrames(2);

    final expected = robot.framebufferHash();

    final robot2 = RomRobot(_romPath);

    robot2.nes.state = NESState.fromBytes(state);

    robot2.runFrames(2);

    expect(robot2.framebufferHash(), expected);
  });

  test('savestate round trip with fine-x set continues byte-identically', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;

    stepTo(nes, 120, 100); // mid-scanline, mid-tile (_bgWindowPos != 0)

    // Force a non-zero fine-x so the pixel window is read through the
    // fine-x mux at save time (pos + x reaches into the next-tile
    // window slots). Reset the $2005 write toggle first so the first
    // write lands as the fine-x/coarse-X write.
    nes.ppu.w = 0;

    nes.bus.cpuWrite(0x2005, 0x05); // fine-x = 5
    nes.bus.cpuWrite(0x2005, 0x00); // second write completes the pair

    final state = nes.state!.serialize();

    robot.runFrames(2);

    final expected = robot.framebufferHash();

    final robot2 = RomRobot(_romPath);

    robot2.nes.state = NESState.fromBytes(state);

    robot2.runFrames(2);

    expect(robot2.framebufferHash(), expected);
  });

  test('state round trip preserves next-tile attributes mid-tile', () {
    final robot = RomRobot(_romPath)..runFrames(60);

    final nes = robot.nes;

    // During vblank, repaint tile row 5 (scanlines 40-47, inside the
    // ROM's static title section) with an opaque tile, set nonzero
    // attributes for the whole screen, and give background palette 1
    // colors distinct from palette 0, so row 40's pixels carry
    // observable attribute bits.
    stepTo(nes, 241, 8);

    final tile = _findTextTile(nes);

    nes.ppu.w = 0;

    _writeVram(nes, 0x20a0, List.filled(32, tile));
    _writeVram(nes, 0x23c0, List.filled(64, 0x55)); // attribute 1
    _writeVram(nes, 0x3f05, const [0x16, 0x27, 0x18]);

    // The ROM's own NMI handler restores scroll; render a full frame
    // so the new tiles and attributes are fetched.
    robot.runFrames(2);

    // Land mid-tile on row 40: 2-5 dots past a reload, so the
    // (conceptual) attribute registers have been serially fed bits of
    // the next tile's attribute.
    stepTo(nes, 40, 100);

    bool midTile() {
      final sinceReload = (nes.ppu.cycle - 1) & 7;

      return sinceReload >= 2 && sinceReload <= 5;
    }

    while (nes.ppu.scanline == 40 && !midTile()) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }

    expect(nes.ppu.scanline, 40);
    expect(nes.ppu.cycle, lessThanOrEqualTo(200));

    // Non-zero fine-x so the pixel mux reads into the next-tile
    // window slots for the remaining dots of this tile.
    nes.ppu.w = 0;

    nes.bus.cpuWrite(0x2005, 0x05); // fine-x = 5
    nes.bus.cpuWrite(0x2005, 0x00); // second write completes the pair

    // Round-trip the state OBJECT: the serialized v0 layout stores the
    // 16-bit pattern registers as single bytes (pre-existing
    // truncation), which blanks the in-flight tile on restore and
    // hides attribute reconstruction errors; the object path keeps
    // the full register width.
    final state = nes.state!;

    // Apply to the second NES before stepping the first: the state
    // object shares live buffers with the running NES until applied.
    final robot2 = RomRobot(_romPath);

    robot2.nes.state = state;

    // Both must render the rest of the in-flight frame identically —
    // compare before the next frame repaints the divergent scanline.
    _finishFrame(robot);
    _finishFrame(robot2);

    expect(robot2.framebufferHash(), robot.framebufferHash());
  });
}
