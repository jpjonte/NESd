import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'palette_import_button.g.dart';

@riverpod
PickFile palettePicker(Ref ref) => FilePicker.pickFile;

class PaletteImportButton extends ConsumerWidget {
  const PaletteImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FocusOnHover(
    child: ButtonSettingsTile(
      title: const Text('Import palette…'),
      onPressed: () => _import(ref),
    ),
  );

  Future<void> _import(WidgetRef ref) async {
    final pickFile = ref.read(palettePickerProvider);
    final palettes = ref.read(userPalettesProvider.notifier);
    final settings = ref.read(settingsControllerProvider.notifier);
    final toaster = ref.read(toasterProvider);

    final file = await pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pal'],
    );

    if (file == null) {
      return;
    }

    final name = p.basenameWithoutExtension(file.name).trim();

    if (name.isEmpty) {
      toaster.send(Toast.error('The palette file needs a name'));

      return;
    }

    try {
      await palettes.import(name, await file.readAsBytes());
    } on FormatException catch (e) {
      toaster.send(Toast.error('Could not import $name: ${e.message}'));

      return;
    } on Object catch (e, s) {
      log.video.error(
        'Failed to import palette $name',
        error: e,
        stackTrace: s,
      );

      toaster.send(Toast.error('Could not import $name'));

      return;
    }

    settings.paletteSelection = UserPaletteSelection(name);

    toaster.send(Toast.info('Imported $name'));
  }
}
