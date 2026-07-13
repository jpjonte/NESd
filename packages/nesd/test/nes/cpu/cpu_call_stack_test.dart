import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../ui/mocks.dart';

/// Minimal in-memory iNES image with mapper 0 (NROM), 32 KB PRG mapped
/// at $8000-$FFFF, 8 KB CHR; `patches` writes bytes at CPU addresses.
NES buildNes(Map<int, int> patches) {
  const prgBanks = 2;
  const chrBanks = 1;

  final rom = Uint8List(16 + prgBanks * 0x4000 + chrBanks * 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, prgBanks, chrBanks, 0, 0]);

  for (final patch in patches.entries) {
    rom[16 + (patch.key - 0x8000)] = patch.value;
  }

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'call-stack-test.nes',
      name: 'call-stack-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  return NES(cartridge: cartridge, eventBus: EventBus())..reset();
}

void main() {
  test('JSR at the top of memory records the wrapped resume address', () {
    final nes = buildNes({
      0xfffd: 0x20, // JSR $9000; the resume address wraps to $0000
      0xfffe: 0x00,
      0xffff: 0x90,
    });

    nes.cpu
      ..callStackEnabled = true
      ..PC = 0xfffd
      ..step();

    // Hardware wraps PC at $FFFF, so the recorded resume address must
    // be $0000: an unmasked $10000 can never match a breakpoint.
    expect(nes.cpu.callStack, [0x0000]);
    expect(nes.cpu.PC, 0x9000);
  });

  test('BRK records exactly one entry and RTI removes it', () {
    final nes = buildNes({
      0x8000: 0x00, // BRK
      0x9000: 0x40, // RTI
      0xfffe: 0x00, // IRQ/BRK vector -> $9000
      0xffff: 0x90,
    });

    nes.cpu
      ..callStackEnabled = true
      ..PC = 0x8000
      ..step();

    expect(nes.cpu.callStack, [0x8002]);
    expect(nes.cpu.PC, 0x9000);

    nes.cpu.step();

    expect(nes.cpu.callStack, isEmpty);
    expect(nes.cpu.PC, 0x8002);
  });

  test('JSR and RTS keep the call stack balanced', () {
    final nes = buildNes({
      0x8000: 0x20, // JSR $9000
      0x8001: 0x00,
      0x8002: 0x90,
      0x9000: 0x60, // RTS
    });

    nes.cpu
      ..callStackEnabled = true
      ..PC = 0x8000
      ..step();

    expect(nes.cpu.callStack, [0x8003]);
    expect(nes.cpu.PC, 0x9000);

    nes.cpu.step();

    expect(nes.cpu.callStack, isEmpty);
    expect(nes.cpu.PC, 0x8003);
  });
}
