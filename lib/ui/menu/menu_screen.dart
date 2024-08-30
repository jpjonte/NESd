import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/dividers.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/common/quit.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/router.dart';

@RoutePage()
class MenuScreen extends HookConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black.withAlpha(200),
      appBar: AppBar(
        title: Text(
          'NESd',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: NesdMenuWrapper(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NesdButton(
                autofocus: true,
                onPressed: () =>
                    ref.read(routerProvider).navigate(const MainRoute()),
                child: const Text('Resume'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () =>
                    ref.read(routerProvider).push(const SettingsRoute()),
                child: const Text('Settings'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () {
                  ref.read(nesControllerProvider).stop();
                  ref.read(routerProvider).navigate(const MainRoute());
                },
                child: const Text('Quit Game'),
              ),
              const NesdVerticalDivider(),
              NesdButton(
                onPressed: () {
                  ref.read(nesControllerProvider).stop();
                  quit();
                },
                child: const Text('Quit NESd'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
