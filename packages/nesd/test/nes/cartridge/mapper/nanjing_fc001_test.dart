import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/nanjing_fc001.dart';
import 'package:nesd/nes/cartridge/mapper/nanjing_fc001_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';
import '../../ppu/four_bpp_harness.dart' show pixelAt, runFrames;

const _prgBankSize = 0x8000;
const _markerOffset = 0x100;

Uint8List _buildRom({int prgBanks = 64}) {
  final prgSize = prgBanks * _prgBankSize;

  final rom = Uint8List(16 + prgSize)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      prgBanks * 2, // 16 KiB PRG units
      0, // CHR-RAM
      0x32, // mapper 163 low nibble, battery, vertical mirroring
      0xa0, // mapper 163 high nibble
    ]);

  for (var bank = 0; bank < prgBanks; bank++) {
    final base = 16 + bank * _prgBankSize;

    rom
      ..setAll(base, [0x4c, 0x00, 0x80]) // JMP $8000
      ..[base + _markerOffset] = bank
      ..setAll(base + _prgBankSize - 6, [0x00, 0x80, 0x00, 0x80, 0x00, 0x80]);
  }

  return rom;
}

NES _buildNes({int prgBanks = 64}) {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'nanjing-fc001-test.nes',
      name: 'nanjing-fc001-test.nes',
      type: FilesystemFileType.file,
    ),
    _buildRom(prgBanks: prgBanks),
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return nes;
}

Cartridge _buildCartridge({int prgBanks = 64}) =>
    _buildNes(prgBanks: prgBanks).bus.cartridge;

int _prgBank(Cartridge cartridge) => cartridge.cpuRead(0x8000 + _markerOffset);

int _feedback(Cartridge cartridge) => cartridge.cpuRead(0x5500);

void _stampChrHalves(Cartridge cartridge) {
  cartridge.chrRam
    ..[0x0000] = 0xa0
    ..[0x1000] = 0xa1;
}

(int, int) _renderHalves({required bool autoSwitch}) {
  final nes = _buildNes(prgBanks: 4);
  final cartridge = nes.bus.cartridge;

  nes.cpu.reset();
  nes.apu.reset();
  nes.ppu.reset();

  for (var row = 0; row < 8; row++) {
    cartridge.chrRam
      ..[row] = 0xff
      ..[0x1000 + 8 + row] = 0xff;
  }

  nes.bus
    ..ppuWrite(0x3f00, 0x0f)
    ..ppuWrite(0x3f01, 0x16)
    ..ppuWrite(0x3f02, 0x2a)
    ..cpuWrite(0x5000, autoSwitch ? 0x80 : 0x00)
    ..cpuWrite(0x2001, 0x0a);

  runFrames(nes, 3);

  return (pixelAt(nes.ppu, 128, 8 * 4), pixelAt(nes.ppu, 128, 8 * 20));
}

void main() {
  group('NanjingFC001', () {
    test('is selected for mapper 163', () {
      expect(_buildCartridge().mapper, isA<NanjingFC001>());
    });

    test('boots in 32 KiB PRG bank 3', () {
      final cartridge = _buildCartridge();

      expect(_prgBank(cartridge), 3);
      expect(cartridge.cpuRead(0xfffc), 0x00);
      expect(cartridge.cpuRead(0xfffd), 0x80);
    });

    test('forces PRG A15/A16 high until the mode register enables them', () {
      final cartridge = _buildCartridge()..cpuWrite(0x5000, 0x04);

      expect(_prgBank(cartridge), 7);

      cartridge.cpuWrite(0x5300, 0x04);

      expect(_prgBank(cartridge), 4);
    });

    test('combines the low and high PRG registers', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5300, 0x04)
        ..cpuWrite(0x5000, 0x8d)
        ..cpuWrite(0x5200, 0x02);

      expect(_prgBank(cartridge), 0x2d);
    });

    test('swaps D0 and D1 of the PRG registers when mode bit 0 is set', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5300, 0x05)
        ..cpuWrite(0x5000, 0x01)
        ..cpuWrite(0x5200, 0x01);

      expect(_prgBank(cartridge), 0x22);
    });

    test('exempts \$5200 from the swap below 2 MiB of PRG-ROM', () {
      final cartridge = _buildCartridge(prgBanks: 32)
        ..cpuWrite(0x5300, 0x05)
        ..cpuWrite(0x5000, 0x01)
        ..cpuWrite(0x5200, 0x01);

      expect(_prgBank(cartridge), 0x12);
    });

    test('does not swap the bits of the mode register itself', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5300, 0x05)
        ..cpuWrite(0x5300, 0x06)
        ..cpuWrite(0x5000, 0x01);

      expect(_prgBank(cartridge), 1);
    });

    test('reads the latched feedback bit back inverted', () {
      final cartridge = _buildCartridge();

      expect(_feedback(cartridge), 0x04);

      cartridge.cpuWrite(0x5100, 0x04);

      expect(_feedback(cartridge), 0x00);
      expect(cartridge.cpuRead(0x5000), 0x00);
      expect(cartridge.cpuRead(0x5100), 0x00);
    });

    test('flips the feedback bit on a falling D0 edge when E is set', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5100, 0x01)
        ..cpuWrite(0x5101, 0x01);

      expect(_feedback(cartridge), 0x04, reason: 'D0=1 is no falling edge');

      cartridge.cpuWrite(0x5101, 0x00);

      expect(_feedback(cartridge), 0x00);

      cartridge.cpuWrite(0x5101, 0x00);

      expect(_feedback(cartridge), 0x04);
    });

    test('never flips the feedback bit while E is clear', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5100, 0x04)
        ..cpuWrite(0x5101, 0x00);

      expect(_feedback(cartridge), 0x00);
    });

    test('applies the bit swap to the flip write', () {
      final cartridge = _buildCartridge()
        ..cpuWrite(0x5300, 0x05)
        ..cpuWrite(0x5100, 0x02) // swapped to E=1
        ..cpuWrite(0x5101, 0x01); // swapped to D0=0

      expect(_feedback(cartridge), 0x00);
    });

    test('ignores \$5800-\$5FFF', () {
      final cartridge = _buildCartridge()..cpuWrite(0x5800, 0x04);

      expect(_prgBank(cartridge), 3);
      expect(cartridge.cpuRead(0x5800), isNot(0x04));
    });

    test('maps 8 KiB of battery-backed PRG-RAM at \$6000', () {
      final cartridge = _buildCartridge()..cpuWrite(0x6123, 0x5a);

      expect(cartridge.hasBattery, isTrue);
      expect(cartridge.cpuRead(0x6123), 0x5a);
      expect(cartridge.prgSaveRam[0x123], 0x5a);
    });

    test('maps the 8 KiB CHR-RAM straight while the auto-switch is off', () {
      final cartridge = _buildCartridge();

      _stampChrHalves(cartridge);

      cartridge.mapper.updatePpuAddress(0x2200);

      expect(cartridge.ppuRead(0x0000), 0xa0);
      expect(cartridge.ppuRead(0x1000), 0xa1);
    });

    test('selects the CHR half from PPU A9 latched on the A13 rise', () {
      final cartridge = _buildCartridge()..cpuWrite(0x5000, 0x80);
      final mapper = cartridge.mapper;

      _stampChrHalves(cartridge);

      mapper.updatePpuAddress(0x2200); // nametable row 16

      expect(cartridge.ppuRead(0x0000), 0xa1);
      expect(cartridge.ppuRead(0x1000), 0xa1);

      mapper
        ..updatePpuAddress(0x0000)
        ..updatePpuAddress(0x2000); // nametable row 0

      expect(cartridge.ppuRead(0x0000), 0xa0);
      expect(cartridge.ppuRead(0x1000), 0xa0);
    });

    test('ignores A9 while A13 stays high', () {
      final cartridge = _buildCartridge()..cpuWrite(0x5000, 0x80);

      _stampChrHalves(cartridge);

      cartridge.mapper
        ..updatePpuAddress(0x2000) // nametable fetch, top half
        ..updatePpuAddress(0x23c0); // attribute fetch, A9 set

      expect(cartridge.ppuRead(0x1000), 0xa0);
    });

    test('writes CHR-RAM unswitched while the auto-switch is on', () {
      final cartridge = _buildCartridge()..cpuWrite(0x5000, 0x80);

      cartridge.mapper.updatePpuAddress(0x2200);
      cartridge.ppuWrite(0x0010, 0x55);

      expect(cartridge.chrRam[0x0010], 0x55);
      expect(cartridge.chrRam[0x1010], 0x00);
    });

    test('restores the banks and the latched CHR half from its state', () {
      final source = _buildCartridge()
        ..cpuWrite(0x5300, 0x04)
        ..cpuWrite(0x5000, 0x85)
        ..cpuWrite(0x5100, 0x05)
        ..cpuWrite(0x5200, 0x01);

      source.mapper.updatePpuAddress(0x2200);

      final state = source.mapper.state as NanjingFC001State;

      expect(state.pa09, isTrue);
      expect(state.pa13, isTrue);

      final target = _buildCartridge()..mapper.state = state;

      _stampChrHalves(target);

      expect(_prgBank(target), 0x15);
      expect(_feedback(target), 0x00);
      expect(target.ppuRead(0x0000), 0xa1);
    });

    test('renders the top and bottom screen halves from different CHR '
        'halves', () {
      final (staticTop, staticBottom) = _renderHalves(autoSwitch: false);
      final (switchedTop, switchedBottom) = _renderHalves(autoSwitch: true);

      expect(staticBottom, staticTop);
      expect(switchedTop, staticTop);
      expect(switchedBottom, isNot(switchedTop));
    });
  });
}
