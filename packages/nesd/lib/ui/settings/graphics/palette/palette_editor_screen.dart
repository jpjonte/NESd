import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_actions.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_save_action.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';
import 'package:nesd/ui/toast/toaster.dart';

@RoutePage()
class PaletteEditorScreen extends HookConsumerWidget {
  const PaletteEditorScreen({super.key});

  static const saveKey = Key('paletteEditorSave');

  static const exportKey = Key('paletteEditorExport');

  static const nameKey = Key('paletteEditorName');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paletteEditorProvider);
    final editor = ref.read(paletteEditorProvider.notifier);

    useEffect(() {
      return () => scheduleMicrotask(editor.closeIfMounted);
    }, const []);

    final nameController = useTextEditingController(text: state?.name ?? '');

    if (state == null) {
      return const NesdScaffold(appBar: NesdAppBar(title: Text('Palette')));
    }

    return PopScope(
      canPop: !state.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }

        final discard = await ConfirmationDialog.show(
          context,
          title: const Text('Discard changes?'),
          content: const Text('The palette has unsaved changes.'),
          confirmLabel: const Text('Discard'),
        );

        if (discard != true || !context.mounted) {
          return;
        }

        Navigator.of(context).pop();
      },
      child: NesdScaffold(
        appBar: NesdAppBar(
          title: const Text('Palette Editor'),
          actions: [
            IconButton(
              key: saveKey,
              icon: const Icon(Icons.save),
              tooltip: 'Save palette',
              onPressed: () => savePalette(context, ref),
            ),
            IconButton(
              key: exportKey,
              icon: const Icon(Icons.save_alt),
              tooltip: 'Export palette',
              onPressed: () => _export(ref),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final nameField = Focus(
              skipTraversal: true,
              child: SettingsTile(
                title: const Text('Name'),
                child: TextField(
                  key: nameKey,
                  controller: nameController,
                  onChanged: editor.setName,
                ),
              ),
            );
            final grid = PaletteSwatchGrid(
              colors: state.colors,
              selected: state.selected,
              onSelected: editor.select,
            );
            final controls = PaletteColorEditor(state: state);

            if (constraints.maxWidth < 600) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nameField,
                    const SizedBox(height: 16),
                    grid,
                    const SizedBox(height: 16),
                    controls,
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [nameField, const SizedBox(height: 16), grid],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: SingleChildScrollView(child: controls)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _export(WidgetRef ref) async {
    final state = ref.read(paletteEditorProvider);

    if (state == null) {
      return;
    }

    final toaster = ref.read(toasterProvider);
    final name = state.name.trim().isEmpty ? 'palette' : state.name.trim();

    try {
      final uri = await ref
          .read(paletteActionsProvider)
          .exportPalette(name, state.colors);

      if (uri == null) {
        return;
      }
    } on Object catch (e, s) {
      log.video.error(
        'Failed to export palette $name',
        error: e,
        stackTrace: s,
      );

      toaster.send(Toast.error('Could not export $name'));

      return;
    }

    toaster.send(Toast.info('Exported $name'));
  }
}
