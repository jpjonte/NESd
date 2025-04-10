import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/settings.dart';

class ScalingDropdown extends HookConsumerWidget {
  const ScalingDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.scaling),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode();

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Scaling'),
        onTap: () => _activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxWidth: 300),
          child: DropdownButtonHideUnderline(
            child: InputDecorator(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(),
              ),
              child: DropdownButton<Scaling>(
                value: setting,
                onChanged:
                    (value) =>
                        controller.scaling = value ?? Scaling.autoInteger,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ),
      ),
    );
  }

  void _activateFirstDescendant(FocusNode focusNode) {
    final childContext = focusNode.descendants.firstOrNull?.context;

    if (childContext != null) {
      const intent = ActivateIntent();

      final flutterAction = Actions.maybeFind(childContext, intent: intent);

      if (flutterAction != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!childContext.mounted) {
            return;
          }

          Actions.of(childContext).invokeAction(flutterAction, intent);
        });
      }
    }
  }
}
