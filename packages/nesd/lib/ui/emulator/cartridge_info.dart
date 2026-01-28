import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/ui/common/key_value.dart';

class CartridgeInfoWidget extends StatelessWidget {
  const CartridgeInfoWidget({required this.cartridge, super.key});

  final Cartridge cartridge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyValue(
              'Filename',
              File(cartridge.file.name).uri.pathSegments.last,
            ),
            KeyValue('ROM format', cartridge.romFormat.toString()),
            KeyValue('PRG ROM size', '${cartridge.prgRom.length} bytes'),
            KeyValue('CHR ROM size', '${cartridge.chrRom.length} bytes'),
            KeyValue('Nametable layout', '${cartridge.nametableLayout}'),
            KeyValue(
              'Alternative nametable layout',
              '${cartridge.alternativeNametableLayout}',
            ),
            KeyValue('Has battery', '${cartridge.hasBattery}'),
            KeyValue('Has trainer', '${cartridge.hasTrainer}'),
            KeyValue('Console type', '${cartridge.consoleType}'),
            KeyValue(
              'Mapper',
              '${cartridge.mapper.name} (${cartridge.mapper.id})',
            ),
            KeyValue('PRG Work RAM size', '${cartridge.prgRam.length} bytes'),
            KeyValue(
              'PRG Save RAM size',
              '${cartridge.prgSaveRam.length} bytes',
            ),
            KeyValue('TV system', '${cartridge.tvSystem}'),
          ],
        ),
      ),
    );
  }
}
