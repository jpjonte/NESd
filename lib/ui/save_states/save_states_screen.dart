import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/save_states/save_states_screen_controller.dart';
import 'package:path/path.dart' as p;

@RoutePage()
class SaveStatesScreen extends HookConsumerWidget {
  const SaveStatesScreen({required this.romInfo, super.key});

  final RomInfo romInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nesController = ref.watch(nesControllerProvider);
    final controller = ref.watch(saveStatesScreenControllerProvider(romInfo));

    final statesSnapshot = useStream(controller.stream);

    if (statesSnapshot.hasError) {
      return const Center(child: Text('Error loading ROMs'));
    }

    if (!statesSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final states = statesSnapshot.data!;

    final nextOpenSlot = useMemoized(() {
      var openSlot = 1;

      for (final state in states) {
        if (state.slot == openSlot) {
          openSlot++;
        }
      }

      return openSlot;
    }, [states]);

    Future<void> delete(BuildContext context, RomTileData romTileData) async {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: const Text('Delete save state?'),
        content: Text(
          'Are you sure you want to delete'
          ' the save state ${romTileData.title}?',
        ),
      );

      if (confirmed == true) {
        controller.delete(romTileData);
      }
    }

    final saveRomTileData = RomTileData(
      romInfo: romInfo,
      title: 'New Save State',
      slot: nextOpenSlot,
    );

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          'Save States - ${p.basenameWithoutExtension(romInfo.file.name)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: FocusChild(
            autofocus: true,
            child: PaginatedGrid(
              children: [
                if (nextOpenSlot < 10 && nesController.isOn)
                  RomTile(
                    romTileData: saveRomTileData,
                    onPressed: () {
                      controller.save(saveRomTileData);

                      ref.read(routerProvider).navigate(const EmulatorRoute());
                    },
                  ),
                for (final romTileData in states)
                  RomTile(
                    romTileData: romTileData,
                    onPressed: () {
                      nesController.loadRom(
                        romTileData.romInfo.file,
                        state: romTileData.state,
                      );

                      ref.read(routerProvider).navigate(const EmulatorRoute());
                    },
                    onRemove: () async => await delete(context, romTileData),
                    contextMenuBuilder:
                        (context, close) => [
                          ListTile(
                            title: const Text('Delete save state'),
                            onTap: () async {
                              close();

                              await delete(context, romTileData);
                            },
                          ),
                        ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
