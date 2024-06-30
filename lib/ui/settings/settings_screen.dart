import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nes/ui/emulator/nes_controller.dart';
import 'package:nes/ui/settings/audio/audio_settings.dart';
import 'package:nes/ui/settings/controls/controls_settings.dart';
import 'package:nes/ui/settings/debug/debug_settings.dart';
import 'package:nes/ui/settings/general/general_settings.dart';
import 'package:nes/ui/settings/graphics/graphics_settings.dart';

@RoutePage()
class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 5);
    final controller = ref.watch(nesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            controller
              ..resume()
              ..lifeCycleListenerEnabled = true;

            AutoRouter.of(context).maybePop();
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TabBar(
                controller: tabController,
                tabs: const [
                  Tab(child: Center(child: Text('General'))),
                  Tab(child: Center(child: Text('Graphics'))),
                  Tab(child: Center(child: Text('Audio'))),
                  Tab(child: Center(child: Text('Controls'))),
                  Tab(child: Center(child: Text('Debug'))),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    GeneralSettings(),
                    GraphicsSettings(),
                    AudioSettings(),
                    ControlsSettings(),
                    DebugSettings(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
