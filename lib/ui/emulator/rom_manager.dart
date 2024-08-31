import 'dart:io';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_manager.g.dart';

@riverpod
String applicationSupportPath(ApplicationSupportPathRef ref) => '';

@riverpod
RomManager romManager(RomManagerRef ref) => RomManager(
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
  int get hashCode => Object.hash(name, hash);
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
    final romName = p.basename(romInfo.path);
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(_getDirectory(component), newFilename);

    return fullPath;
  }
}
