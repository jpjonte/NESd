import 'dart:async';

import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

/// Isolate handle that records sent commands and allows emitting events
/// for testing purposes.
class RecordingNesIsolateHandle implements NesIsolateHandle {
  final StreamController<NesIsolateEvent> _controller =
      StreamController<NesIsolateEvent>.broadcast();

  final List<NesCommand> commands = [];

  @override
  Stream<NesIsolateEvent> get events => _controller.stream;

  @override
  void send(NesCommand command) {
    commands.add(command);
  }

  void emit(NesIsolateEvent event) => _controller.add(event);

  @override
  Future<void> dispose() => _controller.close();
}

RomInfo testRomInfo() => const RomInfo(
  file: FilesystemFile(
    path: 'test.nes',
    name: 'test.nes',
    type: FilesystemFileType.file,
  ),
);

CartridgeInfo testCartridgeInfo() => const CartridgeInfo(
  filename: 'test.nes',
  romFormat: RomFormat.iNes,
  prgRomSize: 0,
  chrRomSize: 0,
  nametableLayout: NametableLayout.horizontal,
  alternativeNametableLayout: false,
  hasBattery: false,
  hasTrainer: false,
  consoleType: ConsoleType.nes,
  mapperName: 'NROM',
  mapperId: 0,
  subMapperId: 0,
  prgRamSize: 0,
  prgSaveRamSize: 0,
  tvSystem: TvSystem.ntsc,
);
