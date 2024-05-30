import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/ui/cartridge_info.dart';
import 'package:nes/ui/display.dart';

class AppWidget extends HookWidget {
  const AppWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cartridgeState = useState<Cartridge?>(null);
    final errorState = useState<String?>(null);

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
                await _loadRom(cartridgeState, errorState);
              },
            ),
          ],
        ),
      ],
      child: Row(
        children: [
          const Expanded(child: DisplayWidget()),
          if (cartridgeState.value case final cartridge?)
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
    ValueNotifier<Cartridge?> cartridgeState,
    ValueNotifier<String?> error,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['nes'],
    );

    if (result == null) {
      return;
    }

    error.value = null;
    cartridgeState.value = null;

    final path = result.files.single.path;

    if (path == null) {
      return;
    }

    try {
      cartridgeState.value = Cartridge.fromFile(path);
    } on Exception catch (e) {
      error.value = 'Failed to load ROM: $e';
    }
  }
}
