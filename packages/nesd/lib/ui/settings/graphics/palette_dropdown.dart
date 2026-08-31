import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/common/activate_first_descendant.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/settings.dart';

class PaletteDropdown extends HookConsumerWidget {
  const PaletteDropdown({this.expand = false, super.key});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(
      settingsControllerProvider.select((s) => s.paletteId),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode(skipTraversal: true);

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Palette'),
        adaptive: true,
        onTap: () => activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<NesPaletteId>(
            value: setting,
            onChanged: (value) =>
                controller.paletteId = value ?? NesPaletteId.defaultPalette,
            items: [
              for (final id in NesPaletteId.values)
                DropdownMenuItem(value: id, child: Text(id.displayName)),
            ],
          ),
        ),
      ),
    );
  }
}
