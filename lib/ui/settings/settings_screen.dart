import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes/ui/settings/audio/audio_settings.dart';
import 'package:nes/ui/settings/controls/control_settings.dart';
import 'package:nes/ui/settings/debug/debug_settings.dart';
import 'package:nes/ui/settings/general/general_settings.dart';
import 'package:nes/ui/settings/graphics/graphics_settings.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  static Future<Object?> open(BuildContext context) async {
    var alreadyOpen = false;

    Navigator.popUntil(context, (route) {
      if (route.settings.name == SettingsScreen.route) {
        alreadyOpen = true;
      }

      return true;
    });

    if (!alreadyOpen) {
      return Navigator.of(context).pushNamed(route);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 5);

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
