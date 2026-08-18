import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/activate_first_descendant.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class LogLevelDropdown extends HookConsumerWidget {
  const LogLevelDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.logLevel),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode(skipTraversal: true);

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Log level'),
        subtitle: const Text('Events below this level are not recorded'),
        adaptive: true,
        onTap: () => activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Dropdown<LogLevel>(
            value: setting,
            onChanged: (value) => controller.logLevel = value ?? LogLevel.info,
            items: const [
              DropdownMenuItem(value: LogLevel.debug, child: Text('Debug')),
              DropdownMenuItem(value: LogLevel.info, child: Text('Info')),
              DropdownMenuItem(value: LogLevel.warning, child: Text('Warning')),
              DropdownMenuItem(value: LogLevel.error, child: Text('Error')),
            ],
          ),
        ),
      ),
    );
  }
}
