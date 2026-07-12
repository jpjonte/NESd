import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _NullDatabase implements NesDatabase {
  const _NullDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

NES _buildNes() {
  const path = '../../roms/test/spritecans-2011/spritecans.nes';
  final bytes = File(path).readAsBytesSync();
  const factory = CartridgeFactory(database: _NullDatabase());

  final cartridge = factory.fromFile(
    const FilesystemFile(
      path: path,
      name: 'spritecans.nes',
      type: FilesystemFileType.file,
    ),
    bytes,
  )..databaseEntry = null;

  return NES(cartridge: cartridge, eventBus: EventBus())..reset();
}

void _runFrames(NES nes, int frames) {
  for (var i = 0; i < frames; i++) {
    final target = nes.ppu.frames + 1;

    while (nes.ppu.frames < target) {
      nes.step();
    }

    nes.apu.sampleIndex = 0;
  }
}

void main() {
  test('NTSC 3-dot fast path is observably identical to the generic '
      'loop', () {
    final fast = _buildNes();
    final generic = _buildNes();

    // Identical warmup through the full console: rendering on,
    // nametables/attributes populated, sprites active.
    _runFrames(fast, 120);
    _runFrames(generic, 120);

    expect(
      fast.state!.serialize(),
      generic.state!.serialize(),
      reason: 'instances must be identical before the divergence test',
    );

    // Drive the PPUs directly over the same dot span: `fast` in exact
    // 3-dot quanta (the fast path's straight-line triple step()),
    // `generic` in 9-dot quanta (the generic while loop). `stepUntil`
    // operates in `consoleCycles` units, where one PPU dot equals
    // `ntscConsoleCyclesPerCycle` (4) consoleCycles, so the fast-path
    // clause (`delta == 3 * ntscConsoleCyclesPerCycle` == 12) only
    // fires when the quantum below is scaled by that constant; a
    // 9-dot quantum (36 consoleCycles) deliberately misses it and
    // falls through to the generic loop. Span: 1359 dots, a common
    // multiple of both quanta (453 fast calls * 3 dots == 151 generic
    // calls * 9 dots == 1359 dots), so both instances land on the
    // same dot.
    const spanDots = 1359;

    for (var i = 0; i < spanDots ~/ 3; i++) {
      fast.ppu.stepUntil(
        fast.ppu.consoleCycles + 3 * ntscConsoleCyclesPerCycle,
      );
    }

    for (var i = 0; i < spanDots ~/ 9; i++) {
      generic.ppu.stepUntil(
        generic.ppu.consoleCycles + 9 * ntscConsoleCyclesPerCycle,
      );
    }

    expect(fast.state!.serialize(), generic.state!.serialize());

    // Cross two frame boundaries (odd-frame skip) the same way, including
    // the skipped-dot frame. One NTSC frame is 341 * 262 = 89,342 dots
    // (89,341 on odd frames); use 180,000 divisible by both quanta (9) so
    // the two instances land on the exact same dot across both parities.
    const frameSpanDots = 180000;

    for (var i = 0; i < frameSpanDots ~/ 3; i++) {
      fast.ppu.stepUntil(
        fast.ppu.consoleCycles + 3 * ntscConsoleCyclesPerCycle,
      );
    }

    for (var i = 0; i < frameSpanDots ~/ 9; i++) {
      generic.ppu.stepUntil(
        generic.ppu.consoleCycles + 9 * ntscConsoleCyclesPerCycle,
      );
    }

    expect(fast.state!.serialize(), generic.state!.serialize());
    expect(fast.ppu.frames, generic.ppu.frames);
  });
}
