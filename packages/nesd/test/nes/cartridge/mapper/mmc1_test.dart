import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/cartridge/cartridge_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../../ui/mocks.dart';

Uint8List _buildRom() {
  const prgSize = 8 * 0x4000;
  const chrSize = 0x2000;

  final rom = Uint8List(16 + prgSize + chrSize)
    ..setAll(0, const [0x4e, 0x45, 0x53, 0x1a, 8, 1, 0x10, 0x00]);

  const prgStart = 16;

  for (var bank = 0; bank < 8; bank++) {
    rom[prgStart + bank * 0x4000] = bank;
  }

  return rom;
}

final _rom = _buildRom();

NES _buildNes() {
  final cartridge = CartridgeFactory(database: MockNesDatabase()).fromFile(
    const FilesystemFile(
      path: 'mmc1-test.nes',
      name: 'mmc1-test.nes',
      type: FilesystemFileType.file,
    ),
    _rom,
  )..databaseEntry = null;

  final nes = NES(cartridge: cartridge, eventBus: EventBus());

  cartridge.reset();

  return nes;
}

void _writeRegister(NES nes, int address, int value) {
  for (var i = 0; i < 5; i++) {
    nes.cpu.cycles += 3;

    nes.bus.cartridge.cpuWrite(address, (value >> i) & 1);
  }
}

void main() {
  test(
    'accepts register writes after a state restore rewinds the CPU clock',
    () {
      final nes = _buildNes();
      final cartridge = nes.bus.cartridge;

      nes.cpu.cycles = 100;

      // Snapshot through bytes, like the rewind buffer does.
      final writer = Payload.write();

      cartridge.state.serialize(writer);

      final snapshot = binarize(writer);

      // The game keeps playing: a register write far in the future leaves
      // its cycle stamp behind.
      nes.cpu.cycles = 50000000;

      _writeRegister(nes, 0xe000, 1);

      // Rewind moves the CPU clock backwards and restores the snapshot.
      nes.cpu.cycles = 100;
      cartridge.state = CartridgeState.deserialize(Payload.read(snapshot));

      _writeRegister(nes, 0xe000, 3);

      expect(cartridge.cpuRead(0x8000), 3);
    },
  );
}
