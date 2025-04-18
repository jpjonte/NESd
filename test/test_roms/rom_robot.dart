import 'dart:io';

import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class RomRobot {
  RomRobot(this.path) {
    final file = File(path);

    final cartridge = Cartridge.fromFile(
      FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
      file.readAsBytesSync(),
    )..databaseEntry = null;

    nes = NES(cartridge: cartridge, eventBus: EventBus())..reset();
  }

  final String path;

  late final NES nes;

  void buttonUp(int controller, NesButton button) {
    nes.bus.buttonUp(controller, button);
  }

  void buttonDown(int controller, NesButton button) {
    nes.bus.buttonDown(controller, button);
  }

  void runUntil(
    int breakAddress, {
    void Function(NES)? expect,
    int? maxCycles,
  }) {
    var cycles = 0;

    while (true) {
      nes.step();

      nes.apu.sampleIndex = 0;

      expect?.call(nes);

      cycles++;

      if (nes.cpu.PC == breakAddress) {
        break;
      }

      if (maxCycles != null && cycles >= maxCycles) {
        throw Exception('Max cycles reached');
      }
    }
  }
}
