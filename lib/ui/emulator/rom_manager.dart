import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_manager.g.dart';

@riverpod
String applicationSupportPath(Ref ref) => '';

@riverpod
RomManager romManager(Ref ref) =>
    RomManager(baseDirectory: ref.watch(applicationSupportPathProvider));

@JsonSerializable()
@immutable
class RomInfo {
  const RomInfo({
    this.name,
    this.path,
    this.hash,
    this.romHash,
    this.chrHash,
    this.prgHash,
  });

  final String? name;
  final String? path;
  final String? hash;
  final String? romHash;
  final String? chrHash;
  final String? prgHash;

  factory RomInfo.fromJson(Map<String, dynamic> json) =>
      _$RomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RomInfoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RomInfo &&
        (other.name == name || other.romHash == romHash || other.hash == hash);
  }

  @override
  int get hashCode => Object.hash(name, romHash);
}

class RomManager {
  static const directoryName = 'NESd';

  RomManager({required this.baseDirectory}) {
    _initializeDirectories();
    _migrateFiles();
  }

  final String baseDirectory;

  void save(RomInfo romInfo, Uint8List data) {
    _getSaveFile(romInfo).writeAsBytesSync(data);
  }

  Uint8List? load(RomInfo romInfo) {
    final saveFile = _getSaveFile(romInfo);

    if (!saveFile.existsSync()) {
      return null;
    }

    return saveFile.readAsBytesSync();
  }

  void saveState(RomInfo romInfo, int slot, Uint8List data) {
    _getSaveStateFile(romInfo, slot).writeAsBytesSync(data);
  }

  Uint8List? loadState(RomInfo romInfo, int slot) {
    final saveStateFile = _getSaveStateFile(romInfo, slot);

    if (!saveStateFile.existsSync()) {
      return null;
    }

    return saveStateFile.readAsBytesSync();
  }

  Uint8List? loadLatestState(RomInfo romInfo) {
    final files = <File>[];

    for (var slot = 0; slot < 10; slot++) {
      final stateFile = _getSaveStateFile(romInfo, slot);

      if (stateFile.existsSync()) {
        files.add(stateFile);
      }
    }

    if (files.isEmpty) {
      return null;
    }

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.first.readAsBytesSync();
  }

  void saveThumbnail(RomInfo romInfo, FrameBuffer frameBuffer) {
    final image = img.Image.fromBytes(
      width: frameBuffer.width,
      height: frameBuffer.height,
      order: img.ChannelOrder.rgba,
      bytes: frameBuffer.pixels.buffer,
    );

    final png = img.encodePng(image);

    getThumbnailFile(romInfo).writeAsBytesSync(png);
  }

  File getThumbnailFile(RomInfo romInfo) {
    final filename = _getFilename('thumbnails', romInfo, '.png');

    return File(filename);
  }

  Future<RomTileData> getRomTileData(RomInfo romInfo) async {
    return RomTileData(
      romInfo: romInfo,
      title: p.basenameWithoutExtension(romInfo.name ?? ''),
      thumbnail: await _getLastThumbnail(romInfo),
    );
  }

  Future<RomTileData?> getRomTileDataForSlot(RomInfo romInfo, int slot) async {
    final saveStateFile = _getSaveStateFile(romInfo, slot);

    if (!saveStateFile.existsSync()) {
      return null;
    }

    final data = saveStateFile.readAsBytesSync();

    try {
      final state = NESState.fromBytes(data);

      final lastModified = saveStateFile.lastModifiedSync();

      return RomTileData(
        romInfo: romInfo,
        title:
            'Slot $slot - ${DateFormat.yMd().add_jms().format(lastModified)}',
        thumbnail: await _getStateThumbnail(state),
        state: state,
        slot: slot,
      );
    } on NesdException {
      return null;
    }
  }

  void deleteSaveState(RomTileData romTileData) {
    final slot = romTileData.slot;

    if (slot == null) {
      return;
    }

    final saveStateFile = _getSaveStateFile(romTileData.romInfo, slot);

    if (saveStateFile.existsSync()) {
      saveStateFile.deleteSync();
    }
  }

  Future<ui.Image> _getStateThumbnail(NESState state) async {
    final frameBuffer = state.ppuState.frameBuffer;

    return convertFrameBufferToImage(frameBuffer);
  }

  Future<ui.Image?> _getLastThumbnail(RomInfo romInfo) async {
    final thumbnailFile = getThumbnailFile(romInfo);

    if (!thumbnailFile.existsSync()) {
      return null;
    }

    final bytes = thumbnailFile.readAsBytesSync();

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    final codec = await descriptor.instantiateCodec();

    final frameInfo = await codec.getNextFrame();

    return frameInfo.image;
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

  File _getSaveFile(RomInfo romInfo) {
    final filename = _getFilename('saves', romInfo, '.sav');

    return File(filename);
  }

  File _getSaveStateFile(RomInfo romInfo, int slot) {
    final filename = _getFilename('states', romInfo, '.$slot.state');

    return File(filename);
  }

  String _getDirectory(String component) => p.join(baseDirectory, component);

  String _getFilename(String component, RomInfo romInfo, String extension) {
    final romName = p.basename(romInfo.path ?? '');
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(_getDirectory(component), newFilename);

    return fullPath;
  }
}
