import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
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

    for (final child in data.findAllElements('game')) {
      final romHash = _getHash(child, 'rom');

      if (romHash == null) {
        continue;
      }

      final name = p.basenameWithoutExtension(
        child.children.whereType<XmlComment>().single.value.trim().replaceAll(
          '\\',
          '/',
        ),
      );

      final chrHash = _getHash(child, 'chrrom');
      final prgHash = _getHash(child, 'prgrom')!;
      final mapper = int.parse(_getAttribute(child, 'pcb', 'mapper')!);
      final region = int.parse(_getAttribute(child, 'console', 'region')!);

      _database[romHash] = NesDatabaseEntry(
        name: name,
        romHash: romHash,
        chrHash: chrHash,
        prgHash: prgHash,
        mapper: mapper,
        region: switch (region) {
          0 => Region.ntsc,
          1 => Region.pal,
          _ => null,
        },
      );
    }
  }

  String? _getAttribute(XmlElement child, String tag, String attribute) {
    return child.findElements(tag).single.getAttribute(attribute);
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
    required this.mapper,
    this.region,
  });

  final String name;
  final String romHash;
  final String? chrHash;
  final String prgHash;
  final int mapper;
  final Region? region;
}
