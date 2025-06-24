import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke:
              (intent) =>
                  controller.themeMode = switch (setting) {
                    ThemeMode.light => ThemeMode.system,
                    ThemeMode.dark => ThemeMode.light,
                    _ => setting,
                  },
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke:
              (intent) =>
                  controller.themeMode = switch (setting) {
                    ThemeMode.system => ThemeMode.light,
                    ThemeMode.light => ThemeMode.dark,
                    _ => setting,
                  },
        ),
      },
      child: FocusOnHover(
        child: SettingsTile(
          title: const Text('Theme Mode'),
          adaptive: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: SegmentedButton<ThemeMode>(
                onSelectionChanged:
                    (value) => controller.themeMode = value.first,
                segments: const [
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'System',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: ThemeMode.system,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'Light',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: ThemeMode.light,
                  ),
                  ButtonSegment(
                    icon: SizedBox(width: 18, height: 18),
                    label: Center(
                      child: Text(
                        'Dark',
                        style: TextStyle(
                          fontVariations: [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    value: ThemeMode.dark,
                  ),
                ],
                selected: {setting},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
