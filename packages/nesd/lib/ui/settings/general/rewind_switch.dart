import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class RewindSwitch extends ConsumerWidget {
  const RewindSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.rewind),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Enable Rewind'),
        subtitle: const Text(
          'Allows rewinding game time, but degrades performance',
        ),
        value: setting,
        onChanged: (value) => controller.rewind = value,
      ),
    );
  }
}
