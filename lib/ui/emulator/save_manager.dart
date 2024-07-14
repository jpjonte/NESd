import 'dart:async';
import 'dart:io';

import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_manager.g.dart';

@riverpod
SaveManager saveManager(SaveManagerRef ref) => SaveManager(
      toaster: ref.watch(toasterProvider),
    );

class SaveManager {
  static const directoryName = 'NESd';

  SaveManager({required this.toaster}) {
    // make sure base directory exists
    _getBaseDirectory();
  }

  final Toaster toaster;

  Future<void> save(NES? nes) async {
    if (nes == null) {
      return;
    }

    final data = nes.save();
    final saveFile = await _getSaveFile(nes);

    if (data != null) {
      saveFile.writeAsBytesSync(data);

      toaster.send(Toast.info('SRAM saved'));
    }
  }

  Future<void> load(NES? nes) async {
    if (nes == null) {
      return;
    }

    final saveFile = await _getSaveFile(nes);

    if (saveFile.existsSync()) {
      nes.load(saveFile.readAsBytesSync());

      toaster.send(Toast.info('SRAM save loaded'));
    }
  }

  Future<void> saveState(NES? nes, int slot) async {
    if (nes == null) {
      return;
    }

    final data = nes.serialize();
    final saveStateFile = await _getSaveStateFile(nes, slot);

    saveStateFile.writeAsBytesSync(data);

    toaster.send(Toast.info('Saved state to slot $slot'));
  }

  Future<void> loadState(NES? nes, int slot) async {
    if (nes == null) {
      return;
    }

    final saveStateFile = await _getSaveStateFile(nes, slot);

    if (saveStateFile.existsSync()) {
      nes.deserialize(saveStateFile.readAsBytesSync());

      toaster.send(Toast.info('State loaded from slot $slot'));
    } else {
      toaster.send(Toast.info('No save state found in slot $slot'));
    }
  }

  Future<File> _getSaveFile(NES nes) async {
    final filename = await _getFilename(nes, '.sav');

    return File(filename);
  }

  Future<File> _getSaveStateFile(NES nes, int slot) async {
    final filename = await _getFilename(nes, '.$slot.state');

    return File(filename);
  }

  Future<String> _getFilename(NES nes, String extension) async {
    final romName = p.basename(nes.bus.cartridge.file);
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(await _getBaseDirectory(), newFilename);

    return fullPath;
  }

  Future<String> _getBaseDirectory() async {
    final appSupport = await getApplicationSupportDirectory();

    return appSupport.path;
  }
}
