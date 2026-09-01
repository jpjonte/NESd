import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';
import 'rom_load_helper.dart';

void main() {
  testWidgets('loadRom loads a whole archive at a Windows path', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        r'C:\roms\collection.zip': zipContaining('game.nes', nestestBytes()),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: r'C:\roms\collection.zip',
      name: 'collection.zip',
    );
  });

  testWidgets('loadRom reads an entry out of an archive at a Windows path', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        r'C:\roms\collection.zip': zipContaining('game.nes', nestestBytes()),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: r'C:\roms\collection.zip:game.nes',
      name: 'game.nes',
    );
  });

  testWidgets('loadRom reads an entry out of an uppercase Windows archive', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        r'C:\roms\COLLECTION.ZIP': zipContaining('game.nes', nestestBytes()),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: r'C:\roms\COLLECTION.ZIP:game.nes',
      name: 'game.nes',
    );
  });

  testWidgets('loadRom reads an entry out of an archive under a directory '
      'whose name contains a colon', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/roms/my:games/collection.zip': zipContaining(
          'game.nes',
          nestestBytes(),
        ),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: '/roms/my:games/collection.zip:game.nes',
      name: 'game.nes',
    );
  });
}
