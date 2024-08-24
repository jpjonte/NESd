import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class ResetBindingsButton extends ConsumerWidget {
  const ResetBindingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);

    return FocusOnHover(
      child: IconButtonSettingsTile(
        title: const Text('Reset Control Bindings'),
        onPressed: controller.resetBindings,
        icon: Icons.restart_alt,
      ),
    );
  }
}
