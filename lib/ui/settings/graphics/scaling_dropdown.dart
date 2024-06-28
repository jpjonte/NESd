import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/graphics/scaling.dart';
import 'package:nes/ui/settings/settings.dart';

class ScalingDropdown extends ConsumerWidget {
  const ScalingDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.scaling));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Scaling'),
      trailing: Container(
        padding: const EdgeInsets.all(4.0),
        constraints: const BoxConstraints(maxWidth: 300),
        child: DropdownMenu<Scaling>(
          initialSelection: setting,
          onSelected: (value) =>
              controller.scaling = value ?? Scaling.autoInteger,
          enableSearch: false,
          dropdownMenuEntries: const [
            DropdownMenuEntry(
              value: Scaling.autoInteger,
              label: 'Auto (integer)',
            ),
            DropdownMenuEntry(
              value: Scaling.autoSmooth,
              label: 'Auto (smooth)',
            ),
            DropdownMenuEntry(
              value: Scaling.x1,
              label: '1x',
            ),
            DropdownMenuEntry(
              value: Scaling.x2,
              label: '2x',
            ),
            DropdownMenuEntry(
              value: Scaling.x3,
              label: '3x',
            ),
            DropdownMenuEntry(
              value: Scaling.x4,
              label: '4x',
            ),
          ],
        ),
      ),
    );
  }
}
