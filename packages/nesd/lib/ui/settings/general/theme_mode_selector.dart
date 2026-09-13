import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/segmented_settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SegmentedSettingsTile<ThemeMode>(
        title: const Text('Theme Mode'),
        values: ThemeMode.values,
        value: setting,
        onChanged: (value) => controller.themeMode = value,
        label: (value) => switch (value) {
          ThemeMode.system => 'System',
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
        },
      ),
    );
  }
}
