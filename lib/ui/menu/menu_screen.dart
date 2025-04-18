import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/router/router.dart';

@RoutePage()
class MenuScreen extends ConsumerWidget {
  static const resumeKey = Key('resume');
  static const saveStatesKey = Key('saveStates');
  static const resetGameKey = Key('resetGame');
  static const quitGameKey = Key('quitGame');
  static const settingsKey = Key('settings');

  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NesdScaffold(
      backgroundColor: Colors.black.withAlpha(200),
      appBar: AppBar(
        title: Text(
          'NESd',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: NesdButton(
                    key: resumeKey,
                    autofocus: true,
                    onPressed:
                        () => ref
                            .read(routerProvider)
                            .navigate(const EmulatorRoute()),
                    child: const Text('Resume'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: saveStatesKey,
                    autofocus: true,
                    onPressed:
                        () => ref
                            .read(routerProvider)
                            .navigate(
                              SaveStatesRoute(
                                romInfo:
                                    ref
                                        .read(nesControllerProvider)
                                        .nes!
                                        .bus
                                        .cartridge
                                        .romInfo,
                              ),
                            ),
                    child: const Text('Save States'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: resetGameKey,
                    onPressed: () {
                      ref.read(nesControllerProvider).reset();
                      ref.read(routerProvider).navigate(const EmulatorRoute());
                    },
                    child: const Text('Reset Game'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: quitGameKey,
                    onPressed: () {
                      ref.read(nesControllerProvider).stop();
                      ref.read(routerProvider).navigate(const MainRoute());
                    },
                    child: const Text('Quit Game'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    key: settingsKey,
                    onPressed:
                        () => ref
                            .read(routerProvider)
                            .navigate(const SettingsRoute()),
                    child: const Text('Settings'),
                  ),
                ),
                const NesdVerticalDivider(),
                Center(
                  child: NesdButton(
                    onPressed: () {
                      ref.read(nesControllerProvider).stop();
                      quit();
                    },
                    child: const Text('Quit NESd'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
