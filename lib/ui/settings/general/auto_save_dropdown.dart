import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/settings/settings.dart';

class AutoSaveDropDown extends ConsumerWidget {
  const AutoSaveDropDown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.autoSaveInterval));
    final controller = ref.read(settingsControllerProvider.notifier);

    return ListTile(
      title: const Text('Auto Save Interval'),
      subtitle: const Text('0 = off'),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        child: TextField(
          textAlign: TextAlign.end,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'off',
          ),
          controller: TextEditingController(text: setting?.toString()),
          onChanged: (value) {
            final interval = int.tryParse(value);

            controller.autoSaveInterval = interval == 0 ? null : interval;
          },
        ),
      ),
    );
  }
}
