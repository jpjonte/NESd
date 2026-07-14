import 'dart:io';

import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

class RomRobot {
  RomRobot(this.path) {
    final file = File(path);

    final cartridgeFactory = CartridgeFactory(database: MockNesDatabase());

    final cartridge = cartridgeFactory.fromFile(
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

  void runFrames(int count) {
    final target = nes.ppu.frames + count;

    while (nes.ppu.frames < target) {
      nes.step();

      nes.apu.sampleIndex = 0;
    }
  }

  /// FNV-1a over the current framebuffer; relies on Dart VM 64-bit
  /// wrapping int arithmetic (tests run on the VM only).
  int framebufferHash() {
    final pixels = nes.ppu.frameBuffer.pixels;

    var hash = 0xcbf29ce484222325;

    for (var i = 0; i < pixels.length; i++) {
      hash = (hash ^ pixels[i]) * 0x100000001b3;
    }

    return hash;
  }
}
