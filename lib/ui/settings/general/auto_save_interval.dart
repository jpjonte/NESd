import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes/ui/common/focus_on_hover.dart';
import 'package:nes/ui/emulator/input/intents.dart';
import 'package:nes/ui/settings/settings.dart';

class AutoSaveInterval extends ConsumerWidget {
  const AutoSaveInterval({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSave =
        ref.watch(settingsControllerProvider.select((s) => s.autoSave));
    final setting =
        ref.watch(settingsControllerProvider.select((s) => s.autoSaveInterval));
    final controller = ref.read(settingsControllerProvider.notifier);

    final current = setting ?? 0;

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
            onInvoke: (intent) => controller.autoSaveInterval = current - 1,),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
            onInvoke: (intent) => controller.autoSaveInterval = current + 1,),
      },
      child: FocusOnHover(
        child: ListTile(
          enabled: autoSave,
          title: const Text('Auto Save Interval'),
          onTap: () {},
          trailing: ExcludeFocusTraversal(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  enabled: autoSave,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  controller: TextEditingController(text: setting?.toString()),
                  onChanged: (value) {
                    final interval = int.tryParse(value);

                    if (interval != null) {
                      controller.autoSaveInterval = interval;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
