import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/activate_first_descendant.dart';
import 'package:nesd/ui/common/dropdown.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/settings.dart';

class PaletteDropdown extends HookConsumerWidget {
  const PaletteDropdown({this.expand = false, super.key});

  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(
      settingsControllerProvider.select((s) => s.paletteSelection),
    );
    final userPalettes = ref.watch(userPalettesProvider).value ?? const {};
    final controller = ref.read(settingsControllerProvider.notifier);
    final focusNode = useFocusNode(skipTraversal: true);

    final items = [
      for (final id in NesPaletteId.values)
        if (id != NesPaletteId.user)
          DropdownMenuItem<PaletteSelection>(
            value: BuiltInPaletteSelection(id),
            child: Text(id.displayName),
          ),
      for (final name in userPalettes.keys.sorted(compareAsciiLowerCase))
        DropdownMenuItem<PaletteSelection>(
          value: UserPaletteSelection(name),
          child: Text(name),
        ),
    ];

    return FocusOnHover(
      focusNode: focusNode,
      child: SettingsTile(
        title: const Text('Palette'),
        adaptive: true,
        onTap: () => activateFirstDescendant(focusNode),
        child: Container(
          padding: const EdgeInsets.all(8),
          constraints: expand ? null : const BoxConstraints(maxWidth: 300),
          child: Dropdown<PaletteSelection>(
            value: selection.effective(userPalettes.keys),
            onChanged: (value) => controller.paletteSelection =
                value ?? PaletteSelection.defaultSelection,
            items: items,
          ),
        ),
      ),
    );
  }
}
