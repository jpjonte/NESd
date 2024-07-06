import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/cartridge_info.dart';
import 'package:nes/ui/emulator/display.dart';
import 'package:nes/ui/emulator/input/action_handler.dart';
import 'package:nes/ui/emulator/input/gamepad_input_handler.dart';
import 'package:nes/ui/emulator/input/keyboard_input_handler.dart';
import 'package:nes/ui/emulator/nes_controller.dart';
import 'package:nes/ui/emulator/tile_debug.dart';
import 'package:nes/ui/router.dart';
import 'package:nes/ui/settings/settings.dart';

@RoutePage()
class EmulatorScreen extends HookConsumerWidget {
  const EmulatorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorState = useState<String?>(null);

    final nes = ref.watch(nesControllerProvider);
    final controller = ref.read(nesControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);

    // make sure services are instantiated
    ref
      ..watch(actionHandlerProvider)
      ..watch(gamepadInputHandlerProvider);

    final keyboardInputHandler = ref.watch(keyboardInputHandlerProvider);

    final cartridge = nes?.bus.cartridge;

    return PlatformMenuBar(
      menus: [
        _mainMenu(context, controller),
        _fileMenu(controller, errorState),
        _gameMenu(controller),
        _audioMenu(settingsController),
      ],
      child: Focus(
        autofocus: true,
        onKeyEvent: (focusNode, event) {
          return keyboardInputHandler.handleKeyEvent(event)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const DisplayWidget(),
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
            ),
            if (settings.showTiles || settings.showCartridgeInfo)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 528),
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (settings.showTiles) const TileDebugWidget(),
                    if (cartridge != null && settings.showCartridgeInfo)
                      CartridgeInfoWidget(cartridge: cartridge),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  PlatformMenu _mainMenu(BuildContext context, NesController controller) {
    final mainMenu = PlatformMenu(
      label: 'NESd',
      menus: [
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.about,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.about,
          ),
        PlatformMenuItem(
          label: 'Settings...',
          shortcut: const CharacterActivator(',', meta: true),
          onSelected: () async {
            controller
              ..lifeCycleListenerEnabled = false
              ..suspend();

            context.router.navigate(const SettingsRoute());
          },
        ),
        PlatformMenuItem(
          label: 'Quit NESd',
          shortcut: const CharacterActivator('q', meta: true),
          onSelected: () {
            controller.save();
            SystemNavigator.pop();
          },
        ),
      ],
    );
    return mainMenu;
  }

  PlatformMenu _fileMenu(
    NesController controller,
    ValueNotifier<String?> errorState,
  ) {
    return PlatformMenu(
      label: 'File',
      menus: [
        PlatformMenuItem(
          label: 'Open...',
          shortcut: const CharacterActivator('o', meta: true),
          onSelected: () {
            errorState.value = null;
            controller.selectRom();
          },
        ),
      ],
    );
  }

  PlatformMenu _gameMenu(NesController controller) {
    return PlatformMenu(
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
    );
  }

  PlatformMenu _audioMenu(SettingsController settingsController) {
    return PlatformMenu(
      label: 'Audio',
      menus: [
        PlatformMenuItem(
          label: 'Volume Up',
          shortcut: const CharacterActivator('+', meta: true),
          onSelected: () => settingsController.volume += 0.1,
        ),
        PlatformMenuItem(
          label: 'Volume Down',
          shortcut: const CharacterActivator('-', meta: true),
          onSelected: () => settingsController.volume -= 0.1,
        ),
      ],
    );
  }
}
