import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/activate_first_descendant.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

class ScalingDropdown extends HookConsumerWidget {
  const ScalingDropdown({this.expand = false, super.key});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.scaling),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode(skipTraversal: true);

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Scaling'),
        adaptive: true,
        onTap: () => activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<Scaling>(
            value: setting,
            onChanged: (value) =>
                controller.scaling = value ?? Scaling.autoInteger,
            items: const [
              DropdownMenuItem(
                value: Scaling.autoInteger,
                child: Text('Auto (integer)'),
              ),
              DropdownMenuItem(
                value: Scaling.autoSmooth,
                child: Text('Auto (smooth)'),
              ),
              DropdownMenuItem(value: Scaling.x1, child: Text('1x')),
              DropdownMenuItem(value: Scaling.x2, child: Text('2x')),
              DropdownMenuItem(value: Scaling.x3, child: Text('3x')),
              DropdownMenuItem(value: Scaling.x4, child: Text('4x')),
            ],
          ),
        ),
      ),
    );
  }
}
