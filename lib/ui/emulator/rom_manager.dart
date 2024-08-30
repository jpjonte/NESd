import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_manager.g.dart';

@riverpod
String applicationSupportPath(ApplicationSupportPathRef ref) => '';

@riverpod
RomManager romManager(RomManagerRef ref) => RomManager(
      toaster: ref.watch(toasterProvider),
      baseDirectory: ref.watch(applicationSupportPathProvider),
    );

@JsonSerializable()
@immutable
class RomInfo {
  const RomInfo({
    required this.name,
    required this.path,
    required this.hash,
  });

  final String name;
  final String path;
  final String hash;

  factory RomInfo.fromJson(Map<String, dynamic> json) =>
      _$RomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RomInfoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RomInfo && (other.name == name || other.hash == hash);
  }

  @override
  int get hashCode => name.hashCode ^ hash.hashCode;
}

class RomManager {
  static const directoryName = 'NESd';

  RomManager({required this.toaster, required this.baseDirectory}) {
    _initializeDirectories();
    _migrateFiles();
  }

  final Toaster toaster;

  final String baseDirectory;

  void save(NES nes) {
    final data = nes.save();
    final saveFile = _getSaveFile(nes.bus.cartridge);

    if (data != null) {
      saveFile.writeAsBytesSync(data);

      toaster.send(Toast.info('SRAM saved'));
    }
  }

  void load(NES nes) {
    final saveFile = _getSaveFile(nes.bus.cartridge);

    if (saveFile.existsSync()) {
      nes.load(saveFile.readAsBytesSync());

      toaster.send(Toast.info('SRAM save loaded'));
    }
  }

  void saveState(NES nes, int slot) {
    final data = nes.serialize();

    _getSaveStateFile(nes.bus.cartridge, slot).writeAsBytesSync(data);

    toaster.send(Toast.info('Saved state to slot $slot'));
  }

  void loadState(NES nes, int slot) {
    final saveStateFile = _getSaveStateFile(nes.bus.cartridge, slot);

    if (saveStateFile.existsSync()) {
      nes.deserialize(saveStateFile.readAsBytesSync());

      toaster.send(Toast.info('State loaded from slot $slot'));
    } else {
      toaster.send(Toast.warning('No save state found in slot $slot'));
    }
  }

  void saveThumbnail(NES nes) {
    final frameBuffer = nes.ppu.frameBuffer;

    final image = img.Image.fromBytes(
      width: frameBuffer.width,
      height: frameBuffer.height,
      order: img.ChannelOrder.rgba,
      bytes: frameBuffer.pixels.buffer,
    );

    final png = img.encodePng(image);

    getThumbnailFile(nes.bus.cartridge.romInfo).writeAsBytesSync(png);
  }

  File getThumbnailFile(RomInfo romInfo) {
    final filename = _getFilename('thumbnails', romInfo, '.png');

    return File(filename);
  }

  void _initializeDirectories() {
    Directory(_getDirectory('saves')).createSync(recursive: true);
    Directory(_getDirectory('states')).createSync(recursive: true);
    Directory(_getDirectory('thumbnails')).createSync(recursive: true);
  }

  void _migrateFiles() {
    _migrateFilesToDirectory('sav', 'saves');
    _migrateFilesToDirectory('state', 'states');
    _migrateFilesToDirectory('png', 'thumbnails');
  }

  void _migrateFilesToDirectory(String extension, String directory) {
    final files = Directory(_getDirectory('')).listSync();

    for (final file in files) {
      if (file is File && p.extension(file.path) == '.$extension') {
        final newPath = p.join(_getDirectory(directory), p.basename(file.path));

        file
          ..copySync(newPath)
          ..deleteSync();
      }
    }
  }

  File _getSaveFile(Cartridge cartridge) {
    final filename = _getFilename('saves', cartridge.romInfo, '.sav');

    return File(filename);
  }

  File _getSaveStateFile(Cartridge cartridge, int slot) {
    final filename = _getFilename('states', cartridge.romInfo, '.$slot.state');

    return File(filename);
  }

  String _getDirectory(String component) => p.join(baseDirectory, component);

  String _getFilename(String component, RomInfo romInfo, String extension) {
    final romName = p.basename(romInfo.path);
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(_getDirectory(component), newFilename);

    return fullPath;
  }
}
