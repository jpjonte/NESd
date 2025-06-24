import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/settings/settings.dart';

class AutoSaveInterval extends HookConsumerWidget {
  const AutoSaveInterval({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSave = ref.watch(
      settingsControllerProvider.select((s) => s.autoSave),
    );
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.autoSaveInterval),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    final current = setting ?? 0;

    final focused = useState(false);

    final colorScheme = Theme.of(context).colorScheme;

    final textEditingController = useTextEditingController(
      text: setting.toString(),
    );

    return Actions(
      actions: {
        DecreaseIntent: CallbackAction<DecreaseIntent>(
          onInvoke: (intent) => controller.autoSaveInterval = current - 1,
        ),
        IncreaseIntent: CallbackAction<IncreaseIntent>(
          onInvoke: (intent) => controller.autoSaveInterval = current + 1,
        ),
      },
      child: FocusOnHover(
        onFocusChange: (value) {
          focused.value = value;

          if (value) {
            textEditingController.selection = TextSelection(
              baseOffset: textEditingController.text.length,
              extentOffset: textEditingController.text.length,
            );
          }
        },
        child: SettingsTile(
          enabled: autoSave,
          title: const Text('Auto Save Interval'),
          subtitle: const Text('Minutes between auto saves'),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                enabled: autoSave,
                cursorColor: focused.value ? colorScheme.onPrimary : null,
                style: TextStyle(
                  color: focused.value ? colorScheme.onPrimary : null,
                ),
                textAlign: TextAlign.end,
                keyboardType: TextInputType.number,
                controller: textEditingController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) {
                      return oldValue;
                    }

                    return newValue;
                  }),
                ],
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
    );
  }
}
