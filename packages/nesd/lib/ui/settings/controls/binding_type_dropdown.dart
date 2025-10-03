import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/settings.dart';

class BindingTypeDropdown extends ConsumerWidget {
  const BindingTypeDropdown({required this.action, super.key});

  final InputAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileIndex = ref.watch(profileIndexProvider);
    final binding = ref.watch(
      settingsControllerProvider.select(
        (s) => s.bindings.firstWhereOrNull(
          (b) => b.index == profileIndex && b.action == action,
        ),
      ),
    );

    return Dropdown<BindingType>(
      value: binding?.type ?? BindingType.hold,
      onChanged: (value) {
        if (binding == null || value == null) {
          return;
        }

        ref
            .read(settingsControllerProvider.notifier)
            .updateBinding(binding.copyWith(type: value));
      },
      items: const [
        DropdownMenuItem(value: BindingType.hold, child: Text('Hold')),
        DropdownMenuItem(value: BindingType.toggle, child: Text('Toggle')),
      ],
    );
  }
}
