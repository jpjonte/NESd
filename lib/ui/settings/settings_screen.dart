import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_menu_wrapper.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/audio/audio_settings.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/debug/debug_settings.dart';
import 'package:nesd/ui/settings/general/general_settings.dart';
import 'package:nesd/ui/settings/graphics/graphics_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_screen.g.dart';

@riverpod
class SettingsTabIndex extends _$SettingsTabIndex {
  @override
  int build() {
    return 0;
  }

  int get index => state;

  set index(int index) {
    state = index;
  }
}

@RoutePage()
class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 5);

    final indexController = ref.watch(settingsTabIndexProvider.notifier);

    useEffect(() {
      void listener() {
        indexController.index = tabController.index;
      }

      tabController.addListener(listener);

      return () => tabController.removeListener(listener);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Actions(
          actions: {
            PreviousTabIntent: CallbackAction<PreviousTabIntent>(
              onInvoke: (intent) => tabController.animateTo(
                (tabController.index - 1) % tabController.length,
              ),
            ),
            NextTabIntent: CallbackAction<NextTabIntent>(
              onInvoke: (intent) => tabController.animateTo(
                (tabController.index + 1) % tabController.length,
              ),
            ),
          },
          child: NesdMenuWrapper(
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
      ),
    );
  }
}
