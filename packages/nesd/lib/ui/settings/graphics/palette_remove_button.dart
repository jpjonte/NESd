import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

class PaletteRemoveButton extends ConsumerWidget {
  const PaletteRemoveButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(
      settingsControllerProvider.select((s) => s.paletteSelection),
    );
    final loaded = ref.watch(userPalettesProvider).value ?? const {};

    final effective = selection.effective(loaded.keys);

    if (effective is! UserPaletteSelection) {
      return const SizedBox.shrink();
    }

    return FocusOnHover(
      child: ButtonSettingsTile(
        title: const Text('Remove palette'),
        onPressed: () => _remove(ref, effective.name),
      ),
    );
  }

  Future<void> _remove(WidgetRef ref, String name) async {
    final palettes = ref.read(userPalettesProvider.notifier);
    final settings = ref.read(settingsControllerProvider.notifier);
    final toaster = ref.read(toasterProvider);

    settings.paletteSelection = PaletteSelection.defaultSelection;

    try {
      await palettes.remove(name);
    } on Object catch (e, s) {
      log.video.error(
        'Failed to remove palette $name',
        error: e,
        stackTrace: s,
      );

      toaster.send(Toast.error('Could not remove $name'));
    }
  }
}
