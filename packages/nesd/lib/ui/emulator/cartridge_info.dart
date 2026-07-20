import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/ui/common/key_value.dart';

/// Cartridge metadata for the debug info panel.
///
/// The full [Cartridge] lives in the emulator isolate and isn't reachable
/// from the UI, so this carries only the fields the panel displays.
@immutable
class CartridgeInfo {
  const CartridgeInfo({
    required this.filename,
    required this.romFormat,
    required this.prgRomSize,
    required this.chrRomSize,
    required this.nametableLayout,
    required this.alternativeNametableLayout,
    required this.hasBattery,
    required this.hasTrainer,
    required this.consoleType,
    required this.mapperName,
    required this.mapperId,
    required this.subMapperId,
    required this.prgRamSize,
    required this.prgSaveRamSize,
    required this.tvSystem,
  });

  factory CartridgeInfo.fromCartridge(Cartridge cartridge) => CartridgeInfo(
    filename: File(cartridge.file.name).uri.pathSegments.last,
    romFormat: cartridge.romFormat,
    prgRomSize: cartridge.prgRom.length,
    chrRomSize: cartridge.chrRom.length,
    nametableLayout: cartridge.nametableLayout,
    alternativeNametableLayout: cartridge.alternativeNametableLayout,
    hasBattery: cartridge.hasBattery,
    hasTrainer: cartridge.hasTrainer,
    consoleType: cartridge.consoleType,
    mapperName: cartridge.mapper.name,
    mapperId: cartridge.mapper.id,
    subMapperId: cartridge.mapper.subMapperId,
    prgRamSize: cartridge.prgRam.length,
    prgSaveRamSize: cartridge.prgSaveRam.length,
    tvSystem: cartridge.tvSystem,
  );

  final String filename;
  final RomFormat romFormat;
  final int prgRomSize;
  final int chrRomSize;
  final NametableLayout nametableLayout;
  final bool alternativeNametableLayout;
  final bool hasBattery;
  final bool hasTrainer;
  final ConsoleType consoleType;
  final String mapperName;
  final int mapperId;
  final int subMapperId;
  final int prgRamSize;
  final int prgSaveRamSize;
  final TvSystem tvSystem;
}

class CartridgeInfoWidget extends StatelessWidget {
  const CartridgeInfoWidget({required this.info, super.key});

  final CartridgeInfo info;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyValue('Filename', info.filename),
            KeyValue('ROM format', info.romFormat.toString()),
            KeyValue('PRG ROM size', '${info.prgRomSize} bytes'),
            KeyValue('CHR ROM size', '${info.chrRomSize} bytes'),
            KeyValue('Nametable layout', '${info.nametableLayout}'),
            KeyValue(
              'Alternative nametable layout',
              '${info.alternativeNametableLayout}',
            ),
            KeyValue('Has battery', '${info.hasBattery}'),
            KeyValue('Has trainer', '${info.hasTrainer}'),
            KeyValue('Console type', '${info.consoleType}'),
            KeyValue(
              'Mapper',
              '${info.mapperName} (${info.mapperId}'
                  ', submapper ${info.subMapperId})',
            ),
            KeyValue('PRG Work RAM size', '${info.prgRamSize} bytes'),
            KeyValue('PRG Save RAM size', '${info.prgSaveRamSize} bytes'),
            KeyValue('TV system', '${info.tvSystem}'),
          ],
        ),
      ),
    );
  }
}
