import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class ResetBindingsButton extends HookConsumerWidget {
  const ResetBindingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);

    final focused = useState(false);

    return FocusOnHover(
      onFocusChange: (value) => focused.value = value,
      child: IconButtonSettingsTile(
        title: const Text('Reset Control Bindings'),
        onPressed: controller.resetBindings,
        icon: Icons.restart_alt,
        color: focused.value ? Theme.of(context).colorScheme.onPrimary : null,
      ),
    );
  }
}
