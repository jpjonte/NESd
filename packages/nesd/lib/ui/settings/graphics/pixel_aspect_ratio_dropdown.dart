import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/activate_first_descendant.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class PixelAspectRatioDropdown extends HookConsumerWidget {
  const PixelAspectRatioDropdown({this.expand = false, super.key});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.pixelAspectRatio),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode(skipTraversal: true);

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Pixel Aspect Ratio'),
        adaptive: true,
        onTap: () => activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<PixelAspectRatio>(
            value: setting,
            onChanged: (value) =>
                controller.pixelAspectRatio = value ?? PixelAspectRatio.auto,
            items: const [
              DropdownMenuItem(
                value: PixelAspectRatio.auto,
                child: Text('Auto'),
              ),
              DropdownMenuItem(
                value: PixelAspectRatio.ntsc,
                child: Text('NTSC'),
              ),
              DropdownMenuItem(value: PixelAspectRatio.pal, child: Text('PAL')),
              DropdownMenuItem(
                value: PixelAspectRatio.square,
                child: Text('Square'),
              ),
              DropdownMenuItem(
                value: PixelAspectRatio.stretch,
                child: Text('Stretch'),
              ),
              DropdownMenuItem(
                value: PixelAspectRatio.custom,
                child: Text('Custom'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
