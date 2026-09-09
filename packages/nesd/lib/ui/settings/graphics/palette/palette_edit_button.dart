import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/settings.dart';

String paletteForkName(String base, Iterable<String> taken) {
  final names = taken.map((name) => name.toLowerCase()).toSet();
  final candidate = '$base copy';

  if (!names.contains(candidate.toLowerCase())) {
    return candidate;
  }

  for (var suffix = 2; ; suffix++) {
    final numbered = '$candidate $suffix';

    if (!names.contains(numbered.toLowerCase())) {
      return numbered;
    }
  }
}

class PaletteEditButton extends ConsumerWidget {
  const PaletteEditButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusOnHover(
    child: ButtonSettingsTile(
      title: const Text('Edit palette…'),
      onPressed: () => _edit(ref),
    ),
  );

  void _edit(WidgetRef ref) {
    final palette = ref.read(nesPaletteProvider);
    final loaded = ref.read(userPalettesProvider).value ?? const {};
    final selection = ref
        .read(settingsControllerProvider)
        .paletteSelection
        .effective(loaded.keys);

    final name = switch (selection) {
      UserPaletteSelection(:final name) => name,
      BuiltInPaletteSelection(:final id) => paletteForkName(
        id.displayName,
        loaded.keys,
      ),
    };

    ref
        .read(paletteEditorProvider.notifier)
        .open(
          name: name,
          colors: paletteBaseColors(palette),
          sourceHadEmphasis: hasCustomEmphasis(palette),
        );

    ref.read(routerProvider).navigate(const PaletteEditorRoute());
  }
}
