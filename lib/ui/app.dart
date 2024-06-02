import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/cartridge_info.dart';
import 'package:nes/ui/display.dart';
import 'package:nes/ui/nes_controller.dart';

class AppWidget extends HookConsumerWidget {
  const AppWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorState = useState<String?>(null);

    final nes = ref.watch(nesControllerProvider);
    final controller = ref.read(nesControllerProvider.notifier);

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'NES',
          menus: [
            PlatformMenuItem(
              label: 'About',
              onSelected: () {},
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'Open...',
              shortcut: const CharacterActivator('o', meta: true),
              onSelected: () async {
                await _loadRom(controller, errorState);
              },
            ),
          ],
        ),
        PlatformMenu(
          label: 'Game',
          menus: [
            PlatformMenuItem(
              label: 'Pause',
              shortcut: const CharacterActivator('p', meta: true),
              onSelected: controller.togglePause,
            ),
            PlatformMenuItem(
              label: 'Reset',
              shortcut: const CharacterActivator('r', meta: true),
              onSelected: controller.reset,
            ),
            PlatformMenuItem(
              label: 'Next Frame',
              shortcut: const CharacterActivator(']', meta: true),
              onSelected: controller.runUntilFrame,
            ),
          ],
        ),
      ],
      child: Row(
        children: [
          const Expanded(child: DisplayWidget()),
          if (nes.bus.cartridge case final cartridge?)
            CartridgeInfoWidget(cartridge: cartridge),
          if (errorState.value != null)
            Text(
              errorState.value!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadRom(
    NesController controller,
    ValueNotifier<String?> error,
  ) async {
    controller.suspend();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['nes'],
    );

    if (result == null) {
      controller.resume();

      return;
    }

    error.value = null;

    final path = result.files.single.path;

    if (path == null) {
      controller.resume();

      return;
    }

    try {
      controller
        ..loadCartridge(path)
        ..run();
    } on Exception catch (e) {
      error.value = 'Failed to load ROM: $e';

      controller.resume();
    }
  }
}
