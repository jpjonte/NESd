import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';

class GamepadSlotsSection extends ConsumerWidget {
  const GamepadSlotsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(gamepadSlotRegistryProvider);

    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        final assignments = registry.assignments;

        if (assignments.isEmpty) {
          return const FocusOnHover(
            child: SettingsTile(child: Text('No gamepads detected')),
          );
        }

        return Column(
          children: [
            for (final assignment in assignments)
              FocusOnHover(
                child: SettingsTile(
                  title: Text('Gamepad ${assignment.slot + 1}'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(assignment.key.name)),
                      IconButton(
                        icon: const Icon(Icons.swap_vert),
                        tooltip: assignment.slot == 0
                            ? null
                            : 'Move to Gamepad ${assignment.slot}',
                        onPressed: assignment.slot == 0
                            ? null
                            : () => registry.assign(
                                assignment.slot - 1,
                                assignment.gamepadId,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
