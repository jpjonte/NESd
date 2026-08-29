import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 10-Yard Fight (rev0), the first entry in assets/nes20db.xml
  const knownRomHash = '55dc03a493150258e10166cf38ed76dfade605d6';
  const knownPrgHash = '64185edc4fd64b5f5e565b90b0ddc241592d899c';

  const file = FilesystemFile(
    path: '/roms/game.nes',
    name: 'game.nes',
    type: FilesystemFileType.file,
  );

  test('finds a known ROM by its rom hash once loaded', () async {
    final database = NesDatabase();

    await database.ready;

    final entry = database.find(
      const RomInfo(file: file, romHash: knownRomHash),
    );

    expect(entry, isNotNull);
    expect(entry!.mapper, 0);
    expect(entry.prgHash, knownPrgHash);
  });

  test('finds a known ROM by its prg hash once loaded', () async {
    final database = NesDatabase();

    await database.ready;

    expect(
      database.find(const RomInfo(file: file, prgHash: knownPrgHash)),
      isNotNull,
    );
  });

  test('hands control back to the event loop while loading', () async {
    final database = NesDatabase();

    var turns = 0;

    void countTurn() {
      turns++;

      Timer.run(countTurn);
    }

    Timer.run(countTurn);

    await database.ready;

    expect(
      turns,
      greaterThan(20),
      reason:
          'the document should be parsed across many event-loop turns, '
          'not in one blocking pass',
    );
  });
}
