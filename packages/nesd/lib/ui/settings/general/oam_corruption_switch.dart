import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class OamCorruptionSwitch extends ConsumerWidget {
  const OamCorruptionSwitch({super.key});

  static const subtitle =
      'Glitches sprites when a game turns rendering off mid-frame, like the '
      'console does';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.oamCorruption),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('OAM Corruption'),
        subtitle: const Text(subtitle),
        value: setting,
        onChanged: (value) => controller.oamCorruption = value,
      ),
    );
  }
}
