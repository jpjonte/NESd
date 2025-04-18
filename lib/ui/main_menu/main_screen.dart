import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toast_overlay.dart';
import 'package:nesd/ui/toast/toaster.dart';

@RoutePage()
class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(nesControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);

    useEffect(() {
      scheduleMicrotask(() {
        Overlay.of(
          context,
        ).insert(OverlayEntry(builder: (context) => const ToastOverlay()));
      });

      return null;
    }, []);

    // make sure services are kept alive
    ref
      ..watch(actionHandlerProvider)
      ..watch(gamepadInputHandlerProvider)
      ..watch(toasterProvider)
      ..watch(nesControllerProvider)
      ..watch(romManagerProvider);

    return PlatformMenuBar(
      menus: [
        _mainMenu(context, controller),
        _fileMenu(controller),
        _gameMenu(controller),
        _audioMenu(settingsController),
      ],
      child: const SafeArea(child: NesdScaffold(body: MainMenu())),
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
          onSelected:
              () async => await context.router.navigate(const SettingsRoute()),
        ),
        PlatformMenuItem(
          label: 'Quit NESd',
          shortcut: const CharacterActivator('q', meta: true),
          onSelected: () {
            controller.stop();
            quit();
          },
        ),
      ],
    );

    return mainMenu;
  }

  PlatformMenu _fileMenu(NesController controller) {
    return PlatformMenu(
      label: 'File',
      menus: [
        PlatformMenuItem(
          label: 'Open...',
          shortcut: const CharacterActivator('o', meta: true),
          onSelected: controller.selectRom,
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
