import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/frame_buffer_image.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rom_manager.g.dart';

@riverpod
String applicationSupportPath(Ref ref) => '';

@riverpod
RomManager romManager(Ref ref) {
  final romManager = RomManager(
    baseDirectory: ref.watch(applicationSupportPathProvider),
    storage: ref.watch(storageFilesystemProvider),
    toaster: ref.watch(toasterProvider),
  );

  ref.onDispose(romManager.dispose);

  return romManager;
}

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

/// The newest save state on disk for a ROM and where it came from.
@immutable
class LatestSaveState {
  const LatestSaveState({
    required this.slot,
    required this.data,
    required this.modified,
  });

  final int slot;
  final Uint8List data;
  final DateTime modified;
}

class RomManager {
  static const directoryName = 'NESd';

  RomManager({
    required this.baseDirectory,
    required this.storage,
    this.toaster,
  }) {
    _initialized = _initialize();
  }

  final String baseDirectory;

  final StorageFilesystem storage;

  final Toaster? toaster;

  // Every public storage operation awaits this so nothing can read or
  // write while the legacy-layout migration is still moving files.
  late final Future<void> _initialized;

  bool _ready = false;

  Future<void> _ensureInitialized() {
    if (_ready) {
      return Future.value();
    }

    return _initialized;
  }

  @visibleForTesting
  Future<void> get initialized => _initialized;

  final thumbnailRevision = ValueNotifier<int>(0);

  void dispose() => thumbnailRevision.dispose();

  Future<void> save(RomInfo romInfo, Uint8List data) async {
    await _ensureInitialized();

    await storage.write(_getFilename('saves', romInfo, '.sav'), data);
  }

  Future<Uint8List?> load(RomInfo romInfo) async {
    await _ensureInitialized();

    return storage.read(_getFilename('saves', romInfo, '.sav'));
  }

  Future<void> saveState(RomInfo romInfo, int slot, List<int> data) async {
    await _ensureInitialized();

    await storage.write(
      _stateFilename(romInfo, slot),
      Uint8List.fromList(data),
    );
  }

  Future<Uint8List?> loadState(RomInfo romInfo, int slot) async {
    await _ensureInitialized();

    return storage.read(_stateFilename(romInfo, slot));
  }

  Future<LatestSaveState?> loadLatestState(RomInfo romInfo) async {
    await _ensureInitialized();

    int? newestSlot;
    DateTime? newestTime;

    for (var slot = 0; slot < 10; slot++) {
      final modified = await storage.lastModified(
        _stateFilename(romInfo, slot),
      );

      if (modified == null) {
        continue;
      }

      if (newestTime == null || modified.isAfter(newestTime)) {
        newestTime = modified;
        newestSlot = slot;
      }
    }

    if (newestSlot == null || newestTime == null) {
      return null;
    }

    final data = await storage.read(_stateFilename(romInfo, newestSlot));

    if (data == null) {
      return null;
    }

    return LatestSaveState(slot: newestSlot, data: data, modified: newestTime);
  }

  /// Keeps a copy of a state this build cannot load next to the original, so
  /// a build that can read it still finds it after auto-save has overwritten
  /// the slot. The copy is named after the original's modification time, so
  /// repeating the backup of the same file rewrites the same copy while a
  /// later unreadable file in that slot gets its own. Returns the copy's
  /// file name.
  Future<String> backupUnreadableState(
    RomInfo romInfo,
    LatestSaveState state,
  ) async {
    await _ensureInitialized();

    final stamp = DateFormat('yyyyMMdd-HHmmss').format(state.modified);
    final path = _getFilename(
      'states',
      romInfo,
      '.${state.slot}.$stamp.state.unreadable',
    );

    await storage.write(path, state.data);

    return p.basename(path);
  }

  Future<void> saveThumbnail(
    RomInfo romInfo, {
    required int width,
    required int height,
    required Uint8List pixels,
  }) async {
    await _ensureInitialized();

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

    await storage.write(thumbnailPath(romInfo), Uint8List.fromList(png));

    thumbnailRevision.value++;
  }

  String thumbnailPath(RomInfo romInfo) =>
      _getFilename('thumbnails', romInfo, '.png');

  Future<Uint8List?> readThumbnail(RomInfo romInfo) async {
    await _ensureInitialized();

    return storage.read(thumbnailPath(romInfo));
  }

  // the tile loads the thumbnail itself, so building the ROM list needs no
  // file IO and does not have to wait for the thumbnail of a stopped game
  RomTileData getRomTileData(RomInfo romInfo) => RomTileData(
    romInfo: romInfo,
    title: p.basenameWithoutExtension(romInfo.file.name),
    thumbnail: const StoredThumbnail(),
  );

  Future<RomTileData?> getRomTileDataForSlot(RomInfo romInfo, int slot) async {
    await _ensureInitialized();

    final path = _stateFilename(romInfo, slot);

    final data = await storage.read(path);

    if (data == null) {
      return null;
    }

    final NESState state;

    try {
      state = NESState.fromBytes(data);
    } on Object catch (e, s) {
      log.rom.warning(
        'Skipping save state slot',
        context: {'slot': slot},
        error: e,
        stackTrace: s,
      );

      return null;
    }

    final lastModified = await storage.lastModified(path) ?? DateTime.now();

    return RomTileData(
      romInfo: romInfo,
      title: 'Slot $slot - ${DateFormat.yMd().add_jms().format(lastModified)}',
      thumbnail: DecodedThumbnail(await _getStateThumbnail(state)),
      state: state,
      slot: slot,
    );
  }

  Future<void> deleteSaveState(RomTileData romTileData) async {
    await _ensureInitialized();

    final slot = romTileData.slot;

    if (slot == null) {
      return;
    }

    await storage.delete(_stateFilename(romTileData.romInfo, slot));
  }

  Future<void> _initialize() async {
    try {
      await storage.createDirectory(_getDirectory('saves'));
      await storage.createDirectory(_getDirectory('states'));
      await storage.createDirectory(_getDirectory('thumbnails'));

      await _migrateFilesToDirectory('.sav', 'saves');
      await _migrateFilesToDirectory('.state', 'states');
      await _migrateFilesToDirectory('.png', 'thumbnails');
    } on Object catch (e, s) {
      log.rom.error('Storage initialization failed', error: e, stackTrace: s);

      toaster?.send(Toast.error('Storage initialization failed: $e'));
    } finally {
      _ready = true;
    }
  }

  Future<void> _migrateFilesToDirectory(
    String extension,
    String directory,
  ) async {
    final files = await storage.list(_getDirectory(''));

    for (final path in files) {
      if (p.extension(path) != extension) {
        continue;
      }

      final data = await storage.read(path);

      if (data == null) {
        continue;
      }

      await storage.write(
        p.join(_getDirectory(directory), p.basename(path)),
        data,
      );
      await storage.delete(path);
    }
  }

  Future<ui.Image> _getStateThumbnail(NESState state) async {
    final frameBuffer = state.ppuState.frameBuffer;

    if (frameBuffer == null) {
      throw NesdException('Save state carries no frame');
    }

    return await convertFrameBufferToImage(frameBuffer);
  }

  String _getDirectory(String component) => p.join(baseDirectory, component);

  String _stateFilename(RomInfo romInfo, int slot) =>
      _getFilename('states', romInfo, '.$slot.state');

  String _getFilename(String component, RomInfo romInfo, String extension) {
    final romName = p.basename(romInfo.file.path);
    final newFilename = p.setExtension(romName, extension);
    final fullPath = p.join(_getDirectory(component), newFilename);

    return fullPath;
  }
}
