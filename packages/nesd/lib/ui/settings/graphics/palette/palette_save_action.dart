import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

String? paletteNameError(String name) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return 'The palette needs a name';
  }

  if (trimmed.contains('/') || trimmed.contains(r'\')) {
    return 'The name cannot contain / or \\';
  }

  return null;
}

Future<void> savePalette(BuildContext context, WidgetRef ref) async {
  final state = ref.read(paletteEditorProvider);

  if (state == null) {
    return;
  }

  final toaster = ref.read(toasterProvider);
  final settings = ref.read(settingsControllerProvider.notifier);
  final editor = ref.read(paletteEditorProvider.notifier);
  final error = paletteNameError(state.name);

  if (error != null) {
    toaster.send(Toast.error(error));

    return;
  }

  final name = state.name.trim();
  final palettes = ref.read(userPalettesProvider.notifier);
  final loaded = ref.read(userPalettesProvider).value ?? const {};

  final originalName = state.originalName.trim();

  final clash = loaded.keys.firstWhere(
    (existing) =>
        existing.toLowerCase() == name.toLowerCase() &&
        existing != originalName,
    orElse: () => '',
  );

  if (clash.isNotEmpty) {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: const Text('Overwrite palette?'),
      content: Text('$clash already exists. Overwrite it?'),
      confirmLabel: const Text('Overwrite'),
    );

    if (confirmed != true) {
      return;
    }
  }

  final saveName = clash.isNotEmpty ? clash : name;

  try {
    await palettes.save(saveName, state.colors);
  } on Object catch (e, s) {
    log.video.error(
      'Failed to save palette $saveName',
      error: e,
      stackTrace: s,
    );

    toaster.send(Toast.error('Could not save $saveName'));

    return;
  }

  settings.paletteSelection = UserPaletteSelection(saveName);

  editor.markSaved(saveName, state.colors);

  toaster.send(Toast.info('Saved $saveName'));
}
