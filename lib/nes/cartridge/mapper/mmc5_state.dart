import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';

class MMC5State extends MapperState {
  const MMC5State({
    required this.prgBankMode,
    required this.prgRamProtect1,
    required this.prgRamProtect2,
    required this.prgRegisters,
    required this.chrBankMode,
    required this.chrRegisters,
    required this.exram,
    required this.filledNametable,
    required this.lastChrAddress,
    required this.chrPageHigh,
    required this.nametables,
    required this.fillModeTile,
    required this.fillModeColor,
    required this.lastPpuAddress,
    required this.ppuIdleCountdown,
    required this.ppuInFrame,
    required this.ppuNtReadCount,
    required this.scanline,
    required this.irqTargetScanline,
    required this.irqEnabled,
    required this.irqPending,
    required this.multiplicand,
    required this.multiplier,
    required this.tileCounter,
    required this.lastExtraChr,
    required this.splitEnabled,
    required this.splitActive,
    required this.splitSide,
    required this.splitTile,
    required this.splitTileAddress,
    required this.splitScroll,
    required this.splitBank,
    required this.extendedRamMode,
    required this.extendedAttributeOffset,
    required this.extendedAttributeFetchCountdown,
    required this.extendedAttributeChrBank,
    super.id = 5,
  });

  factory MMC5State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MMC5State._version0(reader),
      _ => throw InvalidSerializationVersion('MMC5', version),
    };
  }

  factory MMC5State._version0(PayloadReader reader) {
    return MMC5State(
      prgBankMode: reader.get(uint8),
      prgRamProtect1: reader.get(uint8),
      prgRamProtect2: reader.get(uint8),
      prgRegisters: reader.get(list(uint8)),
      chrBankMode: reader.get(uint8),
      chrRegisters: reader.get(list(uint8)),
      exram: Uint8List.fromList(reader.get(list(uint8))),
      filledNametable: Uint8List.fromList(reader.get(list(uint8))),
      lastChrAddress: reader.get(uint16),
      chrPageHigh: reader.get(uint8),
      nametables: reader.get(uint8),
      fillModeTile: reader.get(uint8),
      fillModeColor: reader.get(uint8),
      lastPpuAddress: reader.get(uint16),
      ppuIdleCountdown: reader.get(uint8),
      ppuInFrame: reader.get(boolean),
      ppuNtReadCount: reader.get(uint8),
      scanline: reader.get(uint8),
      irqTargetScanline: reader.get(uint8),
      irqEnabled: reader.get(boolean),
      irqPending: reader.get(boolean),
      multiplicand: reader.get(uint8),
      multiplier: reader.get(uint8),
      tileCounter: reader.get(uint8),
      lastExtraChr: reader.get(boolean),
      splitEnabled: reader.get(boolean),
      splitActive: reader.get(boolean),
      splitSide: reader.get(enumeration(SplitSide.values)),
      splitTile: reader.get(uint8),
      splitTileAddress: reader.get(uint16),
      splitScroll: reader.get(uint8),
      splitBank: reader.get(uint8),
      extendedRamMode: reader.get(uint8),
      extendedAttributeOffset: reader.get(uint8),
      extendedAttributeFetchCountdown: reader.get(uint8),
      extendedAttributeChrBank: reader.get(uint8),
    );
  }

  final int prgBankMode;

  final int prgRamProtect1;
  final int prgRamProtect2;

  final List<int> prgRegisters;

  final int chrBankMode;

  final List<int> chrRegisters;

  final Uint8List exram;

  final Uint8List filledNametable;

  final int lastChrAddress;

  final int chrPageHigh;

  final int nametables;

  final int fillModeTile;
  final int fillModeColor;

  final int lastPpuAddress;

  final int ppuIdleCountdown;
  final bool ppuInFrame;
  final int ppuNtReadCount;
  final int scanline;

  final int irqTargetScanline;
  final bool irqEnabled;
  final bool irqPending;

  final int multiplicand;
  final int multiplier;

  final int tileCounter;

  final bool lastExtraChr;

  final bool splitEnabled;
  final bool splitActive;
  final SplitSide splitSide;
  final int splitTile;
  final int splitTileAddress;
  final int splitScroll;
  final int splitBank;

  final int extendedRamMode;
  final int extendedAttributeOffset;
  final int extendedAttributeFetchCountdown;
  final int extendedAttributeChrBank;

  @override
  int get byteLength => 2065;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBankMode)
      ..set(uint8, prgRamProtect1)
      ..set(uint8, prgRamProtect2)
      ..set(list(uint8), prgRegisters)
      ..set(uint8, chrBankMode)
      ..set(list(uint8), chrRegisters)
      ..set(list(uint8), exram)
      ..set(list(uint8), filledNametable)
      ..set(uint16, lastChrAddress)
      ..set(uint8, chrPageHigh)
      ..set(uint8, nametables)
      ..set(uint8, fillModeTile)
      ..set(uint8, fillModeColor)
      ..set(uint16, lastPpuAddress)
      ..set(uint8, ppuIdleCountdown)
      ..set(boolean, ppuInFrame)
      ..set(uint8, ppuNtReadCount)
      ..set(uint8, scanline)
      ..set(uint8, irqTargetScanline)
      ..set(boolean, irqEnabled)
      ..set(boolean, irqPending)
      ..set(uint8, multiplicand)
      ..set(uint8, multiplier)
      ..set(uint8, tileCounter)
      ..set(boolean, lastExtraChr)
      ..set(boolean, splitEnabled)
      ..set(boolean, splitActive)
      ..set(enumeration(SplitSide.values), splitSide)
      ..set(uint8, splitTile)
      ..set(uint16, splitTileAddress)
      ..set(uint8, splitScroll)
      ..set(uint8, splitBank)
      ..set(uint8, extendedRamMode)
      ..set(uint8, extendedAttributeOffset)
      ..set(uint8, extendedAttributeFetchCountdown)
      ..set(uint8, extendedAttributeChrBank);
  }
}
