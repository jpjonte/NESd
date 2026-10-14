import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class RemoveSpriteLimitSwitch extends ConsumerWidget {
  const RemoveSpriteLimitSwitch({super.key});

  static const subtitle =
      'Remove the limit of 8 sprites per line, reducing flicker ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.removeSpriteLimit),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Remove Sprite Limit'),
        subtitle: const Text(subtitle),
        value: setting,
        onChanged: (value) => controller.removeSpriteLimit = value,
      ),
    );
  }
}
