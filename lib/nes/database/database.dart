import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';

part 'database.g.dart';

@riverpod
NesDatabase database(Ref ref) => NesDatabase();

class NesDatabase {
  NesDatabase() {
    _load();
  }

  final Map<String, NesDatabaseEntry> _database = {};

  NesDatabaseEntry? find(RomInfo info) {
    NesDatabaseEntry? result;

    if (info.romHash case final romHash?) {
      result ??= _database[romHash];
    }

    if (info.prgHash case final prgHash?) {
      result ??= _database.values.firstWhereOrNull(
        (entry) => entry.prgHash == prgHash,
      );
    }

    return result;
  }

  Future<void> _load() async {
    final databaseXml = await rootBundle.loadString('assets/nes20db.xml');
    final data = XmlDocument.parse(databaseXml);

    for (final game in data.findAllElements('game')) {
      final romHash = _getHash(game, 'rom');

      if (romHash == null) {
        continue;
      }

      final name = p.basenameWithoutExtension(
        game.children.whereType<XmlComment>().single.value.trim().replaceAll(
          '\\',
          '/',
        ),
      );

      final chrHash = _getHash(game, 'chrrom');
      final prgHash = _getHash(game, 'prgrom')!;
      final mapper = _getAttribute(game, 'pcb', 'mapper').toIntOrZero();
      final region = _getAttribute(game, 'console', 'region').toIntOrZero();
      final chrRamSize = _getAttribute(game, 'chrram', 'size').toIntOrZero();
      final prgRamSize = _getAttribute(game, 'prgram', 'size').toIntOrZero();
      final prgSaveRamSize =
          _getAttribute(game, 'prgnvram', 'size').toIntOrZero();
      final hasBattery = _getAttribute(game, 'pcb', 'battery') == '1';

      _database[romHash] = NesDatabaseEntry(
        name: name,
        romHash: romHash,
        chrHash: chrHash,
        prgHash: prgHash,
        chrRamSize: chrRamSize,
        prgRamSize: prgRamSize,
        prgSaveRamSize: prgSaveRamSize,
        hasBattery: hasBattery,
        mapper: mapper,
        region: switch (region) {
          0 => Region.ntsc,
          1 => Region.pal,
          _ => null,
        },
        expansion: int.parse(_getAttribute(game, 'expansion', 'type')!),
      );
    }
  }

  String? _getAttribute(XmlElement child, String tag, String attribute) {
    return child.findElements(tag).singleOrNull?.getAttribute(attribute);
  }

  String? _getHash(XmlElement child, String tag) {
    return child
        .findElements(tag)
        .singleOrNull
        ?.getAttribute('sha1')
        ?.toLowerCase();
  }
}

class NesDatabaseEntry {
  const NesDatabaseEntry({
    required this.name,
    required this.romHash,
    required this.chrHash,
    required this.prgHash,
    required this.chrRamSize,
    required this.prgRamSize,
    required this.prgSaveRamSize,
    required this.hasBattery,
    required this.mapper,
    required this.expansion,
    this.region,
  });

  final String name;
  final String romHash;
  final String? chrHash;
  final String prgHash;
  final int chrRamSize;
  final int prgRamSize;
  final int prgSaveRamSize;
  final bool hasBattery;
  final int mapper;
  final int expansion;
  final Region? region;

  bool get hasZapper => expansion == 0x08 || expansion == 0x09;
}
