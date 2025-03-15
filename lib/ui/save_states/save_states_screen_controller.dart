import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/rom_list.dart';
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
  );
}

class SaveStatesScreenController {
  SaveStatesScreenController({required this.romInfo, required this.romManager})
    : streamController = BehaviorSubject<List<RomTileData>>() {
    _fetch();
  }

  final RomInfo romInfo;
  final RomManager romManager;

  final BehaviorSubject<List<RomTileData>> streamController;

  Stream<List<RomTileData>> get stream => streamController.stream;

  void delete(RomTileData romTileData) {
    romManager.deleteSaveState(romTileData);
    _fetch();
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
