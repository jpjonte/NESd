import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../helpers/synthetic_rom.dart';

class _NullNesDatabase implements NesDatabase {
  const _NullNesDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;

  @override
  Future<void> get ready => Future.value();
}

void main() {
  test('core boots a synthetic ROM and emulates frames', () {
    const factory = CartridgeFactory(database: _NullNesDatabase());

    final cartridge = factory.fromFile(
      const FilesystemFile(
        path: 'synthetic.nes',
        name: 'synthetic.nes',
        type: FilesystemFileType.file,
      ),
      syntheticNrom(),
    )..databaseEntry = null;

    final nes = NES(cartridge: cartridge, eventBus: EventBus());

    // Component resets only: NES.reset() would start the async run loop.
    nes.bus.cartridge.reset();
    nes.cpu.reset();
    nes.apu.reset();
    nes.ppu.reset();

    while (nes.ppu.frames < 3) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }

    expect(nes.ppu.frames, greaterThanOrEqualTo(3));
    expect(nes.ppu.frameBuffer.presentedPixels, isNotEmpty);
  });
}
