import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5_state.dart';
import 'package:nesd/nes/cpu/irq_source.dart';

import 'mmc5_harness.dart';

MMC5State buildState({
  List<int> chrRegisters = const [
    0x3ff,
    0x2ab,
    0x155,
    0x300,
    0x0ff,
    0x101,
    0x3fe,
    0x200,
    0x0aa,
    0x055,
    0x123,
    0x321,
  ],
  int extendedAttributeOffset = 1023,
  int chrPageHigh = 2,
  Mmc5AudioState audioState = const Mmc5AudioState.initial(),
}) {
  return MMC5State(
    prgBankMode: 3,
    prgRamProtect1: 2,
    prgRamProtect2: 1,
    prgRegisters: const [0x80, 0x81, 0x82, 0x83, 0xff],
    chrBankMode: 3,
    chrRegisters: chrRegisters,
    exram: Uint8List.fromList(List.generate(0x400, (i) => (i * 31) & 0xff)),
    filledNametable: Uint8List.fromList(
      List.generate(0x400, (i) => (i * 37) & 0xff),
    ),
    lastChrAddress: 0x5127,
    chrPageHigh: chrPageHigh,
    nametables: 0xe4,
    fillModeTile: 0x42,
    fillModeColor: 3,
    lastPpuAddress: 0x3f00,
    ppuIdleCountdown: 2,
    ppuInFrame: true,
    ppuNtReadCount: 1,
    scanline: 120,
    irqTargetScanline: 200,
    irqEnabled: true,
    irqPending: false,
    multiplicand: 0xff,
    multiplier: 0xfe,
    tileCounter: 33,
    lastExtraChr: true,
    splitEnabled: true,
    splitActive: false,
    splitSide: SplitSide.right,
    splitTile: 16,
    splitTileAddress: 0x3f9,
    splitScroll: 0x77,
    splitBank: 0x66,
    extendedRamMode: 1,
    extendedAttributeOffset: extendedAttributeOffset,
    extendedAttributeFetchCountdown: 3,
    extendedAttributeChrBank: 0xbf,
    audioState: audioState,
  );
}

void expectStatesEqual(MMC5State actual, MMC5State expected) {
  expect(actual.prgBankMode, expected.prgBankMode);
  expect(actual.prgRamProtect1, expected.prgRamProtect1);
  expect(actual.prgRamProtect2, expected.prgRamProtect2);
  expect(actual.prgRegisters, expected.prgRegisters);
  expect(actual.chrBankMode, expected.chrBankMode);
  expect(actual.chrRegisters, expected.chrRegisters);
  expect(actual.exram, expected.exram);
  expect(actual.filledNametable, expected.filledNametable);
  expect(actual.lastChrAddress, expected.lastChrAddress);
  expect(actual.chrPageHigh, expected.chrPageHigh);
  expect(actual.nametables, expected.nametables);
  expect(actual.fillModeTile, expected.fillModeTile);
  expect(actual.fillModeColor, expected.fillModeColor);
  expect(actual.lastPpuAddress, expected.lastPpuAddress);
  expect(actual.ppuIdleCountdown, expected.ppuIdleCountdown);
  expect(actual.ppuInFrame, expected.ppuInFrame);
  expect(actual.ppuNtReadCount, expected.ppuNtReadCount);
  expect(actual.scanline, expected.scanline);
  expect(actual.irqTargetScanline, expected.irqTargetScanline);
  expect(actual.irqEnabled, expected.irqEnabled);
  expect(actual.irqPending, expected.irqPending);
  expect(actual.multiplicand, expected.multiplicand);
  expect(actual.multiplier, expected.multiplier);
  expect(actual.tileCounter, expected.tileCounter);
  expect(actual.lastExtraChr, expected.lastExtraChr);
  expect(actual.splitEnabled, expected.splitEnabled);
  expect(actual.splitActive, expected.splitActive);
  expect(actual.splitSide, expected.splitSide);
  expect(actual.splitTile, expected.splitTile);
  expect(actual.splitTileAddress, expected.splitTileAddress);
  expect(actual.splitScroll, expected.splitScroll);
  expect(actual.splitBank, expected.splitBank);
  expect(actual.extendedRamMode, expected.extendedRamMode);
  expect(actual.extendedAttributeOffset, expected.extendedAttributeOffset);
  expect(
    actual.extendedAttributeFetchCountdown,
    expected.extendedAttributeFetchCountdown,
  );
  expect(actual.extendedAttributeChrBank, expected.extendedAttributeChrBank);
  expect(actual.audioState.pcmLevel, expected.audioState.pcmLevel);
  expect(
    actual.audioState.pulse1State.timerPeriod,
    expected.audioState.pulse1State.timerPeriod,
  );
}

void main() {
  test('serialize writes version 2 and round-trips 10-bit CHR banks', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 0, reason: 'MapperState envelope version');
    expect(bytes[1], 5, reason: 'mapper id');
    expect(bytes[2], 2, reason: 'MMC5State version');

    final decoded = MapperState.deserialize(Payload.read(bytes)) as MMC5State;

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 0 payloads', () {
    final original = buildState(
      chrRegisters: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      extendedAttributeOffset: 200,
      chrPageHigh: 0,
    );

    // replicate the exact v0 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 0) // envelope version
      ..set(uint8, 5) // mapper id
      ..set(uint8, 0) // MMC5State version
      ..set(uint8, original.prgBankMode)
      ..set(uint8, original.prgRamProtect1)
      ..set(uint8, original.prgRamProtect2)
      ..set(list(uint8), original.prgRegisters)
      ..set(uint8, original.chrBankMode)
      ..set(list(uint8), original.chrRegisters)
      ..set(list(uint8), original.exram)
      ..set(list(uint8), original.filledNametable)
      ..set(uint16, original.lastChrAddress)
      ..set(uint8, original.chrPageHigh)
      ..set(uint8, original.nametables)
      ..set(uint8, original.fillModeTile)
      ..set(uint8, original.fillModeColor)
      ..set(uint16, original.lastPpuAddress)
      ..set(uint8, original.ppuIdleCountdown)
      ..set(boolean, original.ppuInFrame)
      ..set(uint8, original.ppuNtReadCount)
      ..set(uint8, original.scanline)
      ..set(uint8, original.irqTargetScanline)
      ..set(boolean, original.irqEnabled)
      ..set(boolean, original.irqPending)
      ..set(uint8, original.multiplicand)
      ..set(uint8, original.multiplier)
      ..set(uint8, original.tileCounter)
      ..set(boolean, original.lastExtraChr)
      ..set(boolean, original.splitEnabled)
      ..set(boolean, original.splitActive)
      ..set(enumeration(SplitSide.values), original.splitSide)
      ..set(uint8, original.splitTile)
      ..set(uint16, original.splitTileAddress)
      ..set(uint8, original.splitScroll)
      ..set(uint8, original.splitBank)
      ..set(uint8, original.extendedRamMode)
      ..set(uint8, original.extendedAttributeOffset)
      ..set(uint8, original.extendedAttributeFetchCountdown)
      ..set(uint8, original.extendedAttributeChrBank);

    final decoded =
        MapperState.deserialize(Payload.read(binarize(writer))) as MMC5State;

    expectStatesEqual(decoded, original);
  });

  test('set state restores chrPageHigh', () {
    final mapper = buildMmc5()..state = buildState();

    final restored = mapper.state;

    expect(restored.chrPageHigh, 2);
    expect(restored.chrRegisters, buildState().chrRegisters);
  });

  group('audio state', () {
    test('serialize writes version 2 and round-trips audio state', () {
      final mapper = buildMmc5()
        ..cpuWrite(0x5015, 0x03)
        ..cpuWrite(0x5000, 0xdf)
        ..cpuWrite(0x5003, 0x18)
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x7f)
        ..step()
        ..step();

      final writer = Payload.write();

      mapper.state.serialize(writer);

      final reader = Payload.read(binarize(writer));
      final restored = MapperState.deserialize(reader) as MMC5State;

      final audio = restored.audioState;

      expect(audio.pcmLevel, 0x7f);
      expect(audio.pcmIrqEnabled, true);
      expect(audio.cycles, 2);
      expect(audio.pulse1State.enabled, true);
      expect(audio.pulse1State.duty, 3);
      expect(audio.pulse1State.lengthCounterState.value, 2);
    });

    test('restoring state restores the audible output', () {
      final source = buildMmc5()
        ..cpuWrite(0x5015, 0x01)
        ..cpuWrite(0x5000, 0xdf)
        ..cpuWrite(0x5003, 0x18)
        ..cpuWrite(0x5011, 0x40);

      final target = buildMmc5()..state = source.state;

      expect(target.audio.output, source.audio.output);
      expect(target.audio.output, greaterThan(0));
    });

    test('a version 1 state loads with silent audio', () {
      final original = buildState();

      // replicate the exact v1 wire format the previous code produced:
      // like v0, but chrRegisters is list(uint16) and
      // extendedAttributeOffset is uint16, to fit the 10-bit CHR banks
      // the MMC5's extra-CHR mode introduced.
      final writer = Payload.write()
        ..set(uint8, 0) // envelope version
        ..set(uint8, 5) // mapper id
        ..set(uint8, 1) // MMC5State version
        ..set(uint8, original.prgBankMode)
        ..set(uint8, original.prgRamProtect1)
        ..set(uint8, original.prgRamProtect2)
        ..set(list(uint8), original.prgRegisters)
        ..set(uint8, original.chrBankMode)
        ..set(list(uint16), original.chrRegisters)
        ..set(list(uint8), original.exram)
        ..set(list(uint8), original.filledNametable)
        ..set(uint16, original.lastChrAddress)
        ..set(uint8, original.chrPageHigh)
        ..set(uint8, original.nametables)
        ..set(uint8, original.fillModeTile)
        ..set(uint8, original.fillModeColor)
        ..set(uint16, original.lastPpuAddress)
        ..set(uint8, original.ppuIdleCountdown)
        ..set(boolean, original.ppuInFrame)
        ..set(uint8, original.ppuNtReadCount)
        ..set(uint8, original.scanline)
        ..set(uint8, original.irqTargetScanline)
        ..set(boolean, original.irqEnabled)
        ..set(boolean, original.irqPending)
        ..set(uint8, original.multiplicand)
        ..set(uint8, original.multiplier)
        ..set(uint8, original.tileCounter)
        ..set(boolean, original.lastExtraChr)
        ..set(boolean, original.splitEnabled)
        ..set(boolean, original.splitActive)
        ..set(enumeration(SplitSide.values), original.splitSide)
        ..set(uint8, original.splitTile)
        ..set(uint16, original.splitTileAddress)
        ..set(uint8, original.splitScroll)
        ..set(uint8, original.splitBank)
        ..set(uint8, original.extendedRamMode)
        ..set(uint16, original.extendedAttributeOffset)
        ..set(uint8, original.extendedAttributeFetchCountdown)
        ..set(uint8, original.extendedAttributeChrBank);

      final decoded =
          MapperState.deserialize(Payload.read(binarize(writer))) as MMC5State;

      expectStatesEqual(decoded, original);

      expect(decoded.audioState.pcmLevel, 0);
      expect(decoded.audioState.pulse1State.enabled, false);
    });

    test('restoring a state mid-PCM-IRQ re-asserts the bus line', () {
      final source = buildMmc5()
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00);

      final target = buildMmc5()..state = source.state;

      expect(target.bus.cpu.irq & IrqSource.mapperAudio.value, isNot(0));
    });

    test('restoring a state with no pending PCM IRQ clears the bus line', () {
      final source = buildMmc5();

      final target = buildMmc5()
        ..cpuWrite(0x5010, 0x80)
        ..cpuWrite(0x5011, 0x00)
        ..state = source.state;

      expect(target.bus.cpu.irq & IrqSource.mapperAudio.value, 0);
    });
  });
}
