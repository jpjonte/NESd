import 'dart:typed_data';

import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/axrom.dart';
import 'package:nesd/nes/cartridge/mapper/br909x.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom.dart';
import 'package:nesd/nes/cartridge/mapper/gxrom.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5.dart';
import 'package:nesd/nes/cartridge/mapper/namco108.dart';
import 'package:nesd/nes/cartridge/mapper/namco163.dart';
import 'package:nesd/nes/cartridge/mapper/nrom.dart';
import 'package:nesd/nes/cartridge/mapper/unrom.dart';

enum CpuMemoryType { prgRom, prgRam }

enum PpuMemoryType { chrRom, chrRam, nametable }

enum MemoryAccess {
  none(0),
  read(1),
  write(2),
  readWrite(3);

  const MemoryAccess(this.value);

  final int value;

  bool supports(MemoryAccess other) {
    return value & other.value > 0;
  }
}

const _cpuBlockAddressWidth = 10;
const _cpuBlockSize = 1 << _cpuBlockAddressWidth;
const _cpuBlockMask = _cpuBlockSize - 1;
const _cpuBlockCount = 0x10000 ~/ _cpuBlockSize;

const _ppuBlockAddressWidth = 10;
const _ppuBlockSize = 1 << _ppuBlockAddressWidth;
const _ppuBlockMask = _ppuBlockSize - 1;
const _ppuBlockCount = 0x4000 ~/ _ppuBlockSize;

class MemoryMapping {
  MemoryMapping({required this.source, this.access = MemoryAccess.read});

  Uint8List source;
  MemoryAccess access;

  bool supports(MemoryAccess other) => access.supports(other);
}

abstract class Mapper {
  Mapper(this.id);

  factory Mapper.fromId(int mapper) {
    return switch (mapper) {
      0 => NROM(),
      1 => MMC1(),
      2 => UNROM(),
      3 => CNROM(),
      4 => MMC3(),
      5 => MMC5(),
      7 => AxROM(),
      9 => MMC2(),
      19 => Namco163(),
      66 => GxROM(),
      71 => BR909x(),
      206 => Namco108(),
      _ => throw UnsupportedMapper(mapper),
    };
  }

  final int id;

  late final Bus bus;

  late final Cartridge cartridge;

  // we don't need a getter
  // ignore: avoid_setters_without_getters
  set nametableLayout(NametableLayout layout) {
    switch (layout) {
      case NametableLayout.vertical:
        setNametables(0, 0, 1, 1);
      case NametableLayout.horizontal:
        setNametables(0, 1, 0, 1);
      case NametableLayout.singleLower:
        setNametables(0, 0, 0, 0);
      case NametableLayout.singleUpper:
        setNametables(1, 1, 1, 1);
      case NametableLayout.four:
        setNametables(0, 1, 2, 3);
    }
  }

  void setNametables(
    int nametable0,
    int nametable1,
    int nametable2,
    int nametable3,
  ) {
    setNametable(0, nametable0);
    setNametable(1, nametable1);
    setNametable(2, nametable2);
    setNametable(3, nametable3);
  }

  void setNametable(int index, int page) {
    final offset = index * 0x400;

    mapPpu(
      0x2000 + offset,
      0x23ff + offset,
      page,
      type: PpuMemoryType.nametable,
    );
  }

  MapperState get state;

  set state(MapperState state);

  String get name;

  int get prgRomPageSize => 0x4000;

  int get prgRamPageSize => 0x2000;

  late final List<MemoryMapping?> _cpuMapping = List.filled(
    _cpuBlockCount,
    null,
  );

  int get chrPageSize => 0x2000;

  late final List<MemoryMapping?> _ppuMapping = List.filled(
    _ppuBlockCount,
    null,
  );

  void reset() {
    nametableLayout = cartridge.nametableLayout;

    mapCpu(0x6000, 0x7fff, 0, type: CpuMemoryType.prgRam);

    mapPpu(0x0000, 0x1fff, 0);
  }

  void step() {}

  int cpuRead(int address, {bool disableSideEffects = false}) {
    final mapping = _mapCpuAddress(address);

    if (mapping == null) {
      return 0;
    }

    if (mapping.supports(MemoryAccess.read)) {
      final source = mapping.source;
      final offset = address & _cpuBlockMask;

      return source[offset % source.length];
    }

    return 0;
  }

  int ppuRead(int address, {bool disableSideEffects = false}) {
    if (address < 0x3f00) {
      final mapping = _mapPpuAddress(address);

      if (mapping == null) {
        return 0;
      }

      if (mapping.supports(MemoryAccess.read)) {
        final source = mapping.source;
        final offset = address & _ppuBlockMask;

        return source[offset % source.length];
      }
    }

    return 0;
  }

  MemoryMapping? _mapPpuAddress(int address) {
    return _ppuMapping[address >> _ppuBlockAddressWidth];
  }

  MemoryMapping? _mapCpuAddress(int address) {
    return _cpuMapping[address >> _cpuBlockAddressWidth];
  }

  void cpuWrite(int address, int value) {
    final mapping = _mapCpuAddress(address);

    if (mapping == null) {
      return;
    }

    if (mapping.supports(MemoryAccess.write)) {
      mapping.source[address & _cpuBlockMask] = value;
    }
  }

  void ppuWrite(int address, int value) {
    final mapping = _mapPpuAddress(address);

    if (mapping == null) {
      return;
    }

    if (mapping.supports(MemoryAccess.write)) {
      mapping.source[address & _ppuBlockMask] = value;
    }
  }

  void updatePpuAddress(int address) {}

  void mapCpu(
    int fromAddress,
    int toAddress,
    int page, {
    int? pageSize,
    Uint8List? source,
    CpuMemoryType? type,
    MemoryAccess? access,
  }) {
    final resolvedType = type ?? CpuMemoryType.prgRom;

    final resolvedSource =
        source ??
        switch (resolvedType) {
          CpuMemoryType.prgRom => cartridge.prgRom,
          CpuMemoryType.prgRam => cartridge.sram,
        };

    final resolvedPageSize =
        pageSize ??
        switch (resolvedType) {
          CpuMemoryType.prgRom => prgRomPageSize,
          CpuMemoryType.prgRam => prgRamPageSize,
        };

    final resolvedAccess =
        access ??
        switch (resolvedType) {
          CpuMemoryType.prgRom => MemoryAccess.read,
          CpuMemoryType.prgRam => MemoryAccess.readWrite,
        };

    for (
      var address = fromAddress;
      address <= toAddress;
      address += _cpuBlockSize
    ) {
      final block = address >> _cpuBlockAddressWidth;
      final addressDiff = address - fromAddress;
      final offset =
          (page * resolvedPageSize + addressDiff) % resolvedSource.length;

      _cpuMapping[block] =
          resolvedSource.isNotEmpty
              ? MemoryMapping(
                source: Uint8List.sublistView(
                  resolvedSource,
                  offset,
                  offset + _cpuBlockSize,
                ),
                access: resolvedAccess,
              )
              : null;
    }
  }

  void mapPpu(
    int fromAddress,
    int toAddress,
    int page, {
    int? pageSize,
    Uint8List? source,
    PpuMemoryType? type,
    MemoryAccess? access,
  }) {
    final resolvedType =
        type ??
        switch (cartridge.chrRomSize) {
          0 => PpuMemoryType.chrRam,
          _ => PpuMemoryType.chrRom,
        };

    final resolvedSource =
        source ??
        switch (resolvedType) {
          PpuMemoryType.chrRom => cartridge.chr,
          PpuMemoryType.chrRam => cartridge.chr,
          PpuMemoryType.nametable => bus.ppu.ram,
        };

    final resolvedPageSize =
        pageSize ??
        switch (resolvedType) {
          PpuMemoryType.chrRom => chrPageSize,
          PpuMemoryType.chrRam => chrPageSize,
          PpuMemoryType.nametable => 0x400,
        };

    final resolvedAccess =
        access ??
        switch (resolvedType) {
          PpuMemoryType.chrRom => MemoryAccess.read,
          PpuMemoryType.chrRam => MemoryAccess.readWrite,
          PpuMemoryType.nametable => MemoryAccess.readWrite,
        };

    for (
      var address = fromAddress;
      address <= toAddress;
      address += _ppuBlockSize
    ) {
      final block = address >> _ppuBlockAddressWidth;
      final addressDiff = address - fromAddress;
      final offset =
          (page * resolvedPageSize + addressDiff) % resolvedSource.length;

      _ppuMapping[block] =
          resolvedSource.isNotEmpty
              ? MemoryMapping(
                source: Uint8List.sublistView(
                  resolvedSource,
                  offset,
                  offset + _ppuBlockSize,
                ),
                access: resolvedAccess,
              )
              : null;
    }
  }
}
