import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/emulator/main_menu/recent_rom_list.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router.dart';
import 'package:path/path.dart' as p;

@RoutePage()
class SaveStatesScreen extends HookConsumerWidget {
  const SaveStatesScreen({required this.romInfo, super.key});

  final RomInfo romInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(nesControllerProvider);
    final romManager = ref.watch(romManagerProvider);

    final romsFuture = useMemoized(
      () => _getRomTileDataForRom(romManager, romInfo),
      [romInfo],
    );

    final romsSnapshot = useFuture(romsFuture);

    if (romsSnapshot.hasError) {
      return const Center(child: Text('Error loading ROMs'));
    }

    if (!romsSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final roms = romsSnapshot.data!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Save States - ${p.basenameWithoutExtension(romInfo.name)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: FocusChild(
            autofocus: true,
            child: RomList(
              roms: roms,
              onPressed: (romTileData) {
                controller.loadRom(
                  romTileData.romInfo.path,
                  state: romTileData.state,
                );
                ref.read(routerProvider).navigate(const MainRoute());
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<List<RomTileData>> _getRomTileDataForRom(
    RomManager romManager,
    RomInfo romInfo,
  ) async {
    final romTileDatas = <RomTileData>[];

    for (var slot = 0; slot < 10; slot++) {
      final romTileData = await romManager.getRomTileDataForSlot(romInfo, slot);

      if (romTileData == null) {
        continue;
      }

      romTileDatas.add(romTileData);
    }

    return romTileDatas;
  }
}
