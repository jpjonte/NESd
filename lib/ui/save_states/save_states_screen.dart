import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/rom_list.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/router.dart';
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

    final romsSnapshot = useStream(controller.stream);

    if (romsSnapshot.hasError) {
      return const Center(child: Text('Error loading ROMs'));
    }

    if (!romsSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final roms = romsSnapshot.data!;

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
                nesController.loadRom(
                  romTileData.romInfo.path,
                  state: romTileData.state,
                );
                ref.read(routerProvider).navigate(const MainRoute());
              },
              onRemove:
                  (romTileData) async => await delete(context, romTileData),
              contextMenuBuilder:
                  (context, romTileData, close) => [
                    ListTile(
                      title: const Text('Delete save state'),
                      onTap: () async {
                        close();

                        await delete(context, romTileData);
                      },
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }
}
