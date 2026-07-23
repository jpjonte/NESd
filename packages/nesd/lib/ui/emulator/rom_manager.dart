import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/frame_buffer_image.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;
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
    required this.file,
    this.hash,
    this.romHash,
    this.chrHash,
    this.prgHash,
  });

  final FilesystemFile file;
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
        (other.file.name == file.name ||
            other.romHash == romHash ||
            other.hash == hash);
  }

  @override
  int get hashCode => Object.hash(file.name, romHash);
}

class RomManager {
  static const directoryName = 'NESd';

  RomManager({required this.baseDirectory}) {
    _initializeDirectories();
    _migrateFiles();
  }

  final String baseDirectory;

  Future<void> save(RomInfo romInfo, Uint8List data) async {
    final file = _getSaveFile(romInfo);

    await _ensureDirectoryExists(file);

    await file.writeAsBytes(data);
  }

  Uint8List? load(RomInfo romInfo) {
    final saveFile = _getSaveFile(romInfo);

    if (!saveFile.existsSync()) {
      return null;
    }

    return saveFile.readAsBytesSync();
  }

  Future<void> saveState(RomInfo romInfo, int slot, List<int> data) async {
    final file = _getSaveStateFile(romInfo, slot);

    await _ensureDirectoryExists(file);

    await file.writeAsBytes(data);
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

  Future<void> saveThumbnail(
    RomInfo romInfo, {
    required int width,
    required int height,
    required Uint8List pixels,
  }) async {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.buffer,
      bytesOffset: pixels.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    // PNG encode stays synchronous: one-shot at stop(), not a hot path
    final png = img.encodePng(image);

    final file = getThumbnailFile(romInfo);

    await _ensureDirectoryExists(file);

    await file.writeAsBytes(png);
  }

  File getThumbnailFile(RomInfo romInfo) {
    final filename = _getFilename('thumbnails', romInfo, '.png');

    return File(filename);
  }

  Future<RomTileData> getRomTileData(RomInfo romInfo) async {
    return RomTileData(
      romInfo: romInfo,
      title: p.basenameWithoutExtension(romInfo.file.name),
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

  Future<void> deleteSaveState(RomTileData romTileData) async {
    final slot = romTileData.slot;

    if (slot == null) {
      return;
    }

    final saveStateFile = _getSaveStateFile(romTileData.romInfo, slot);

    if (saveStateFile.existsSync()) {
      await saveStateFile.delete();
    }
  }

  Future<void> _ensureDirectoryExists(File file) =>
      Directory(p.dirname(file.path)).create(recursive: true);

  Future<ui.Image> _getStateThumbnail(NESState state) async {
    final frameBuffer = state.ppuState.frameBuffer;

    return await convertFrameBufferToImage(frameBuffer);
  }

  Future<ui.Image?> _getLastThumbnail(RomInfo romInfo) async {
    final thumbnailFile = getThumbnailFile(romInfo);

    if (!thumbnailFile.existsSync()) {
      return null;
    }

    try {
      final bytes = thumbnailFile.readAsBytesSync();

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

      final descriptor = await ui.ImageDescriptor.encoded(buffer);

      final codec = await descriptor.instantiateCodec();

      final frameInfo = await codec.getNextFrame();

      return frameInfo.image;
    } on Exception {
      // a broken thumbnail should not prevent the ROM from being listed
      return null;
    }
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
    final romName = p.basename(romInfo.file.path);
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(_getDirectory(component), newFilename);

    return fullPath;
  }
}
