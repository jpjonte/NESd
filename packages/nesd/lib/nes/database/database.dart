import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/util/wait.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

part 'database.g.dart';

@riverpod
NesDatabase database(Ref ref) => NesDatabase();

class NesDatabase {
  static const _chunkSize = 64 * 1024;

  NesDatabase() {
    _ready = _load();
  }

  late final Future<void> _ready;

  Future<void> get ready => _ready;

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
    final data = await rootBundle.load('assets/nes20db.xml');

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final stream = _chunks(bytes)
        .transform(utf8.decoder)
        .toXmlEvents()
        .selectSubtreeEvents((event) => event.name == 'game')
        .toXmlNodes();

    await for (final nodes in stream) {
      for (final node in nodes) {
        if (node is XmlElement) {
          _addGame(node);
        }
      }
    }
  }

  Stream<List<int>> _chunks(Uint8List bytes) async* {
    for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
      // give other tasks a chance to compute
      await wait(Duration.zero);

      yield Uint8List.sublistView(
        bytes,
        offset,
        min(offset + _chunkSize, bytes.length),
      );
    }
  }

  void _addGame(XmlElement game) {
    final romHash = _getHash(game, 'rom');

    if (romHash == null) {
      return;
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
    final submapper = _getAttribute(game, 'pcb', 'submapper').toIntOrZero();
    final region = _getAttribute(game, 'console', 'region').toIntOrZero();
    final chrRamSize = _getAttribute(game, 'chrram', 'size').toIntOrZero();
    final prgRamSize = _getAttribute(game, 'prgram', 'size').toIntOrZero();
    final prgSaveRamSize = _getAttribute(
      game,
      'prgnvram',
      'size',
    ).toIntOrZero();
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
      submapper: submapper,
      region: switch (region) {
        0 => Region.ntsc,
        1 => Region.pal,
        _ => null,
      },
      expansion: int.parse(_getAttribute(game, 'expansion', 'type')!),
    );
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
    required this.submapper,
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
  final int submapper;
  final int expansion;
  final Region? region;

  bool get hasZapper => expansion == 0x08 || expansion == 0x09;
}
