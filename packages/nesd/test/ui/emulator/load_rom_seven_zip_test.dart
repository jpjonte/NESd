import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';
import 'rom_load_helper.dart';

void main() {
  testWidgets('loadRom loads the only ROM in a 7z archive', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {'/roms/collection.7z': sevenZipFixture('single_rom.7z')},
    );

    await expectRomLoads(
      tester,
      r,
      path: '/roms/collection.7z',
      name: 'collection.7z',
    );
  });

  testWidgets('loadRom reads an entry out of a 7z archive', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {'/roms/collection.7z': sevenZipFixture('solid_roms.7z')},
    );

    await expectRomLoads(
      tester,
      r,
      path: '/roms/collection.7z:scanline.nes',
      name: 'scanline.nes',
    );
  });

  testWidgets('loadRom reads an entry out of an uppercase 7z archive', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {'/roms/COLLECTION.7Z': sevenZipFixture('single_rom.7z')},
    );

    await expectRomLoads(
      tester,
      r,
      path: '/roms/COLLECTION.7Z:nestest.nes',
      name: 'nestest.nes',
    );
  });
}
