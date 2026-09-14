import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final dropdownFocus = useFocusNode(skipTraversal: true);

    const items = [
      DropdownMenuItem(value: PixelAspectRatio.auto, child: Text('Auto')),
      DropdownMenuItem(value: PixelAspectRatio.ntsc, child: Text('NTSC')),
      DropdownMenuItem(value: PixelAspectRatio.pal, child: Text('PAL')),
      DropdownMenuItem(value: PixelAspectRatio.square, child: Text('Square')),
      DropdownMenuItem(value: PixelAspectRatio.stretch, child: Text('Stretch')),
      DropdownMenuItem(value: PixelAspectRatio.custom, child: Text('Custom')),
    ];

    void step(int delta) {
      final next = stepDropdownValue(items, controller.pixelAspectRatio, delta);

      if (next != null) {
        controller.pixelAspectRatio = next;
      }
    }

    return FocusOnHover(
      child: SettingsTile(
        title: const Text('Pixel Aspect Ratio'),
        adaptive: true,
        onTap: () => openDropdown(dropdownFocus),
        onDecrease: () => step(-1),
        onIncrease: () => step(1),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<PixelAspectRatio>(
            focusNode: dropdownFocus,
            value: setting,
            onChanged: (value) =>
                controller.pixelAspectRatio = value ?? PixelAspectRatio.auto,
            items: items,
          ),
        ),
      ),
    );
  }
}
