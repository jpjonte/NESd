import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nes/nes/cartridge/cartridge.dart';

class CartridgeInfoWidget extends StatelessWidget {
  const CartridgeInfoWidget({
    required this.cartridge,
    super.key,
  });

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
            TableRow('Filename', File(cartridge.file).uri.pathSegments.last),
            TableRow('ROM format', cartridge.romFormat.toString()),
            TableRow('PRG ROM size', '${cartridge.prgRomSize} bytes'),
            TableRow('CHR ROM size', '${cartridge.chrRomSize} bytes'),
            TableRow('Nametable layout', '${cartridge.nametableLayout}'),
            TableRow(
              'Alternative nametable layout',
              '${cartridge.alternativeNametableLayout}',
            ),
            TableRow('Has battery', '${cartridge.hasBattery}'),
            TableRow('Has trainer', '${cartridge.hasTrainer}'),
            TableRow('Console type', '${cartridge.consoleType}'),
            TableRow(
              'Mapper',
              '${cartridge.mapper.name} (${cartridge.mapper.id})',
            ),
            TableRow('PRG RAM size', '${cartridge.prgRamSize} bytes'),
            TableRow('TV system', '${cartridge.tvSystem}'),
          ],
        ),
      ),
    );
  }
}

class TableRow extends StatelessWidget {
  const TableRow(
    this.label,
    this.value, {
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
