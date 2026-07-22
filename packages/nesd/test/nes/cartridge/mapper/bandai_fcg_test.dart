import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_fcg.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_fcg_state.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

/// 2x16KB PRG, 1x8KB CHR, with marker bytes so tests can tell banks
/// apart: PRG bank n starts with 0xb0 + n, CHR 1KB page n is filled
/// with 0x10 + n.
Uint8List _buildRom() {
  final rom = Uint8List(16 + 2 * 0x4000 + 0x2000)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 2, 1, 0x00, 0x10]);

  const prgStart = 16;
  const chrStart = prgStart + 2 * 0x4000;

  for (var bank = 0; bank < 2; bank++) {
    rom[prgStart + bank * 0x4000] = 0xb0 + bank;
  }

  for (var page = 0; page < 8; page++) {
    rom.fillRange(
      chrStart + page * 0x400,
      chrStart + (page + 1) * 0x400,
      0x10 + page,
    );
  }

  return rom;
}

/// Bandai FCG with the 256-byte EEPROM attached. Built directly because
/// [CartridgeFactory] only creates the EEPROM for a 256-byte save RAM
/// size, which comes from the ROM database, not the iNES header.
(Cartridge, NES) _buildBandaiFcgWithEeprom() {
  final rom = _buildRom();

  final cartridge = Cartridge(
    file: const FilesystemFile(
      path: 'bandai-eeprom-test.nes',
      name: 'bandai-eeprom-test.nes',
      type: FilesystemFileType.file,
    ),
    rom: rom,
    prgRom: Uint8List.sublistView(rom, 16, 16 + 2 * 0x4000),
    chrRom: Uint8List.sublistView(rom, 16 + 2 * 0x4000),
    chrRam: Uint8List(0),
    prgRam: Uint8List(0),
    prgSaveRam: Uint8List(256),
    nametableLayout: NametableLayout.horizontal,
    alternativeNametableLayout: false,
    hasBattery: true,
    hasTrainer: false,
    mapper: BandaiFCG(0, 256),
    consoleType: ConsoleType.nes,
    romFormat: RomFormat.iNes,
    tvSystem: TvSystem.ntsc,
    fileHash: '',
    romHash: '',
    chrHash: '',
    prgHash: '',
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (cartridge, nes);
}

Eeprom24C02State _idleEepromState(Uint8List data) => Eeprom24C02State(
  previousScl: 0,
  previousSda: 0,
  address: 0,
  bit: 0,
  control: 0,
  shift: 0,
  flush: false,
  mode: Eeprom24C02Mode.idle,
  buffer: Uint8List(16),
  data: data,
  output: 1,
);

/// Minimal mapper 16 image (submapper 0, so FCG-1/2 registers at
/// $6000-$7FFF respond): 2x16KB PRG, 1x8KB CHR.
(Cartridge, NES) _buildBandaiFcg() {
  final rom = _buildRom();

  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'bandai-test.nes',
      name: 'bandai-test.nes',
      type: FilesystemFileType.file,
    ),
    rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return (cartridge, nes);
}

void main() {
  test('IRQ counter wraps as 16-bit and fires after a full period', () {
    final (cartridge, nes) = _buildBandaiFcg();
    final mapper = cartridge.mapper;

    bool irqAsserted() => (nes.cpu.irq & IrqSource.mapper.value) != 0;

    // Counter is 0 after reset; enabling asserts IRQ immediately (level
    // behavior while the counter is 0). Clear it to observe the wrap.
    cartridge.cpuWrite(0x600a, 1);
    nes.bus.clearIrq(IrqSource.mapper);

    // 0 wraps to $FFFF and counts down; after 65535 steps it is at 1.
    for (var i = 0; i < 0xffff; i++) {
      mapper.step();
    }

    expect(irqAsserted(), isFalse);

    // The 65536th step reaches 0 and fires.
    mapper.step();

    expect(irqAsserted(), isTrue);
  });

  test('set state restores banking, mirroring, and IRQ behavior', () {
    final (cartridge, _) = _buildBandaiFcg();

    cartridge
      ..cpuWrite(0x6000, 5) // CHR page 0 -> bank 5
      ..cpuWrite(0x6008, 1) // PRG page 1 at $8000
      ..cpuWrite(0x6009, 3) // single-screen upper
      ..cpuWrite(0x600b, 5) // IRQ counter low
      ..cpuWrite(0x600c, 0) // IRQ counter high
      ..cpuWrite(0x600a, 1); // enable IRQ

    final state = (cartridge.mapper as BandaiFCG).state;

    expect(state.eeprom, isNull);

    final (cartridge2, nes2) = _buildBandaiFcg();
    final mapper2 = (cartridge2.mapper as BandaiFCG)..state = state;

    final restored = mapper2.state;

    expect(restored.chrPages, state.chrPages);
    expect(restored.prgPage, 1);
    expect(restored.nametableLayout, NametableLayout.singleUpper);
    expect(restored.irqEnabled, isTrue);
    expect(restored.irqCounter, 5);

    expect(cartridge2.ppuRead(0), 0x15);
    expect(cartridge2.cpuRead(0x8000), 0xb1);
    expect(cartridge2.cpuRead(0xc000), 0xb1);

    for (var i = 0; i < 4; i++) {
      mapper2.step();
    }

    expect(nes2.cpu.irq & IrqSource.mapper.value, 0);

    mapper2.step();

    expect(nes2.cpu.irq & IrqSource.mapper.value, isNot(0));
  });

  test('state carries the EEPROM and set state restores its contents', () {
    final (cartridge, _) = _buildBandaiFcgWithEeprom();
    final mapper = cartridge.mapper as BandaiFCG;

    final source = mapper.state;

    expect(source.eeprom, isNotNull);

    final data = Uint8List(256)..[0x10] = 0x42;

    mapper.state = BandaiFCGState(
      chrPages: source.chrPages,
      prgPage: source.prgPage,
      nametableLayout: source.nametableLayout,
      irqEnabled: source.irqEnabled,
      irqCounter: source.irqCounter,
      irqLatch: source.irqLatch,
      eeprom: _idleEepromState(data),
    );

    expect(mapper.state.eeprom!.data[0x10], 0x42);
    expect(mapper.save(), data);
  });

  test('cartridge load routes battery data into the EEPROM', () {
    final (cartridge, _) = _buildBandaiFcgWithEeprom();
    final mapper = cartridge.mapper as BandaiFCG;

    final data = Uint8List(256)..[0x10] = 0x42;

    cartridge.load(data);

    expect(mapper.state.eeprom!.data[0x10], 0x42);
    expect(cartridge.save(), data);
  });

  test('a short save fills only the start of the EEPROM', () {
    final (cartridge, _) = _buildBandaiFcgWithEeprom();
    final mapper = cartridge.mapper as BandaiFCG;

    cartridge.load(Uint8List.fromList([1, 2, 3]));

    final data = mapper.state.eeprom!.data;

    expect(data.sublist(0, 3), [1, 2, 3]);
    expect(data.sublist(3), everyElement(0));
  });

  test('header mirroring applies until the game writes register 9', () {
    final (cartridge, _) = _buildBandaiFcg();
    final mapper = cartridge.mapper as BandaiFCG;

    // flags6 = 0x00 parses as a vertical nametable layout
    expect(cartridge.nametableLayout, NametableLayout.vertical);
    expect(mapper.state.nametableLayout, NametableLayout.vertical);

    // vertical layout: $2000 and $2400 share a nametable page
    cartridge.ppuWrite(0x2000, 0xab);

    expect(cartridge.ppuRead(0x2400), 0xab);
  });

  test('game-written mirroring survives a soft reset', () {
    final (cartridge, _) = _buildBandaiFcg();
    final mapper = cartridge.mapper as BandaiFCG;

    cartridge
      ..cpuWrite(0x6009, 3) // single-screen upper
      ..reset();

    expect(mapper.state.nametableLayout, NametableLayout.singleUpper);
  });

  test('LZ93D50 registers at \$8000+ control banking, mirroring, and IRQ', () {
    final (cartridge, nes) = _buildBandaiFcg();
    final mapper = cartridge.mapper as BandaiFCG;

    cartridge
      ..cpuWrite(0x8000, 3) // CHR page 0 -> bank 3
      ..cpuWrite(0x8008, 1) // PRG page 1 at $8000
      ..cpuWrite(0x8009, 2) // single-screen lower
      ..cpuWrite(0x800b, 4) // IRQ latch low
      ..cpuWrite(0x800c, 0) // IRQ latch high
      ..cpuWrite(0x800a, 1); // enable IRQ, copies latch to counter

    // enabling checks the counter before the latch copy; it was 0, so
    // the IRQ asserts immediately — clear it to observe the countdown
    expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));

    nes.bus.clearIrq(IrqSource.mapper);

    expect(cartridge.ppuRead(0), 0x13);
    expect(cartridge.cpuRead(0x8000), 0xb1);

    final state = mapper.state;

    expect(state.nametableLayout, NametableLayout.singleLower);
    expect(state.irqCounter, 4);
    expect(state.irqLatch, 4);

    for (var i = 0; i < 3; i++) {
      mapper.step();
    }

    expect(nes.cpu.irq & IrqSource.mapper.value, 0);

    mapper.step();

    expect(nes.cpu.irq & IrqSource.mapper.value, isNot(0));
  });

  test('register writes do not echo into the RAM mapped at \$6000', () {
    final (cartridge, _) = _buildBandaiFcg();

    cartridge.cpuWrite(0x6000, 5); // CHR register write

    expect(cartridge.cpuRead(0x6000), 0);
  });

  test('unhandled registers still fall through to RAM', () {
    final (cartridge, _) = _buildBandaiFcg();

    cartridge.cpuWrite(0x600e, 0x77); // not a register on either chip

    expect(cartridge.cpuRead(0x600e), 0x77);
  });

  test('register 9 selects mirroring, not arrangement', () {
    final (cartridge, _) = _buildBandaiFcg();

    // value 0 is vertical mirroring: $2000/$2800 share a page,
    // $2400 is the other page
    cartridge
      ..cpuWrite(0x8009, 0)
      ..ppuWrite(0x2000, 0xab);

    expect(cartridge.ppuRead(0x2800), 0xab);
    expect(cartridge.ppuRead(0x2400), 0);

    // value 1 is horizontal mirroring: $2000/$2400 share a page
    cartridge
      ..cpuWrite(0x8009, 1)
      ..ppuWrite(0x2000, 0xcd);

    expect(cartridge.ppuRead(0x2400), 0xcd);
  });

  test('each CHR register maps its own 1KB page', () {
    final (cartridge, _) = _buildBandaiFcg();

    // reversed on purpose: the reset default is page i -> bank i,
    // so an ignored write would be caught
    for (var i = 0; i < 8; i++) {
      cartridge.cpuWrite(0x8000 + i, 7 - i);
    }

    for (var i = 0; i < 8; i++) {
      expect(cartridge.ppuRead(i * 0x400), 0x10 + (7 - i));
    }
  });

  test('LZ93D50 register \$800d drives the EEPROM serial port', () {
    final (cartridge, _) = _buildBandaiFcgWithEeprom();
    final mapper = cartridge.mapper as BandaiFCG;

    // scl is bit 5, sda is bit 6: clock high with a falling data line
    // is an I2C START condition, which puts the chip in control mode
    cartridge
      ..cpuWrite(0x800d, 0x60)
      ..cpuWrite(0x800d, 0x20);

    expect(mapper.state.eeprom!.mode, Eeprom24C02Mode.control);
  });
}
