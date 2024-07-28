import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class CartridgeSwitch extends ConsumerWidget {
  const CartridgeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref
        .watch(settingsControllerProvider.select((s) => s.showCartridgeInfo));
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: SwitchSettingsTile(
        title: const Text('Show Cartridge Information'),
        value: setting,
        onChanged: (value) => controller.showCartridgeInfo = value,
      ),
    );
  }
}
