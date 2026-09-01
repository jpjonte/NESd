import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';
import 'rom_load_helper.dart';

void main() {
  testWidgets('loadRom accepts an uppercase .NES extension', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(extraFiles: {'/test/roms/GAME.NES': nestestBytes()});

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/GAME.NES',
      name: 'GAME.NES',
    );
  });

  testWidgets('loadRom accepts an uppercase .ZIP extension', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': zipContaining('game.nes', nestestBytes()),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/COLLECTION.ZIP',
      name: 'COLLECTION.ZIP',
    );
  });

  testWidgets('loadRom finds an uppercase .NES entry inside an archive', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/collection.zip': zipContaining('GAME.NES', nestestBytes()),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/collection.zip',
      name: 'collection.zip',
    );
  });

  testWidgets('loadRom reads an entry picked out of an uppercase .ZIP', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': zipContaining('game.nes', nestestBytes()),
      },
    );

    // The file picker hands archive entries back as `<archive>:<entry>`.
    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/COLLECTION.ZIP:game.nes',
      name: 'game.nes',
    );
  });
}
