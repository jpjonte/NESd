import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/router.dart';

@RoutePage()
class MenuScreen extends HookConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: FilledButton(
                  autofocus: true,
                  onPressed: () =>
                      ref.read(routerProvider).navigate(const EmulatorRoute()),
                  child: const Text('Resume'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(routerProvider).push(const SettingsRoute()),
                  child: const Text('Settings'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () {
                    ref.read(nesControllerProvider).stop();
                    ref.read(routerProvider).navigate(const EmulatorRoute());
                  },
                  child: const Text('Quit Game'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () => SystemChannels.platform
                      .invokeMethod('SystemNavigator.pop'),
                  child: const Text('Quit NESd'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
