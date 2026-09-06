import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/settings/navigation/settings_navigation.dart';
import 'package:nesd/ui/settings/navigation/stacked_settings.dart';
import 'package:nesd/ui/settings/navigation/two_pane_settings.dart';

@RoutePage()
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twoPane = MediaQuery.sizeOf(context).width >= settingsTwoPaneMinWidth;

    final category = ref.watch(
      settingsNavigationProvider.select((s) => s.category),
    );

    final title = twoPane || category == null ? 'Settings' : category.title;

    final theme = Theme.of(context);

    return NesdScaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
      ),
      body: twoPane ? const TwoPaneSettings() : const StackedSettings(),
    );
  }
}
