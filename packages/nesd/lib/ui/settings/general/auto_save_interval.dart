import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class AutoSaveInterval extends HookConsumerWidget {
  const AutoSaveInterval({super.key});

  static const subtitle = 'Minutes between auto saves';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSave = ref.watch(
      settingsControllerProvider.select((s) => s.autoSave),
    );
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.autoSaveInterval),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    final focused = useState(false);

    final colorScheme = Theme.of(context).colorScheme;

    final textEditingController = useTextEditingController(
      text: setting.toString(),
    );

    final tileFocus = useFocusNode(debugLabel: 'auto save interval tile');
    final textFocus = useFocusNode(skipTraversal: true);

    useEffect(() {
      if (!textFocus.hasFocus &&
          textEditingController.text != setting.toString()) {
        textEditingController.text = setting.toString();
      }

      return null;
    }, [setting]);

    void selectAll() {
      textEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textEditingController.text.length,
      );
    }

    void edit() {
      textFocus.requestFocus();
      selectAll();
    }

    void leave() => tileFocus.requestFocus();

    void stepBy(int delta) {
      controller.autoSaveInterval = controller.autoSaveInterval + delta;
    }

    return FocusOnHover(
      onFocusChange: (value) => focused.value = value,
      child: SettingsTile(
        focusNode: tileFocus,
        enabled: autoSave,
        title: const Text('Auto Save Interval'),
        subtitle: const Text(subtitle),
        onTap: edit,
        onDecrease: () => stepBy(-1),
        onIncrease: () => stepBy(1),
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                leave();

                return null;
              },
            ),
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                leave();

                return null;
              },
            ),
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                focusNode: textFocus,
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
