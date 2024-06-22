import 'dart:io';

import 'package:nes/nes/nes.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SaveManager {
  static const directoryName = 'NESd';

  SaveManager() {
    // make sure base directory exists
    _getBaseDirectory();
  }

  Future<void> save(NES nes) async {
    final save = nes.save();

    if (save != null) {
      final saveFile = await _getSaveFile(nes);

      saveFile.writeAsBytesSync(save);
    }
  }

  Future<void> load(NES nes) async {
    final saveFile = await _getSaveFile(nes);

    if (saveFile.existsSync()) {
      nes.load(saveFile.readAsBytesSync());
    }
  }

  Future<void> saveState(NES nes, int slot) async {
    final data = nes.serialize();
    final saveStateFile = await _getSaveStateFile(nes, slot);

    saveStateFile.writeAsBytesSync(data);
  }

  Future<void> loadState(NES nes, int slot) async {
    final saveStateFile = await _getSaveStateFile(nes, slot);

    if (saveStateFile.existsSync()) {
      nes.deserialize(saveStateFile.readAsBytesSync());
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
