import 'dart:async';

import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'save_states_screen_controller.g.dart';

@riverpod
SaveStatesScreenController saveStatesScreenController(
  Ref ref,
  RomInfo romInfo,
) {
  return SaveStatesScreenController(
    romInfo: romInfo,
    romManager: ref.watch(romManagerProvider),
    nesController: ref.watch(nesControllerProvider),
  );
}

class SaveStatesScreenController {
  SaveStatesScreenController({
    required this.romInfo,
    required this.romManager,
    required this.nesController,
  }) : streamController = BehaviorSubject<List<RomTileData>>() {
    _fetch();
  }

  final RomInfo romInfo;
  final RomManager romManager;

  final NesController nesController;

  final BehaviorSubject<List<RomTileData>> streamController;

  Stream<List<RomTileData>> get stream => streamController.stream;

  Future<void> save(RomTileData romTileData) async {
    final slot = romTileData.slot;

    if (slot == null) {
      return;
    }

    // Await the save before refreshing: _fetch() reads the on-disk slots,
    // so kicking it off before saveState resolves would race the write and
    // show a stale (or missing) thumbnail for the slot just saved.
    await nesController.saveState(slot);

    await _fetch();
  }

  Future<void> delete(RomTileData romTileData) async {
    await romManager.deleteSaveState(romTileData);

    await _fetch();
  }

  Future<void> _fetch() async {
    final romTileDatas = <RomTileData>[];

    for (var slot = 0; slot < 10; slot++) {
      final romTileData = await romManager.getRomTileDataForSlot(romInfo, slot);

      if (romTileData == null) {
        continue;
      }

      romTileDatas.add(romTileData);
    }

    streamController.add(romTileDatas);
  }
}
