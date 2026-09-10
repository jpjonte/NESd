import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_save_action.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';

@RoutePage()
class PaletteEditorScreen extends HookConsumerWidget {
  const PaletteEditorScreen({super.key});

  static const saveKey = Key('paletteEditorSave');

  static const nameKey = Key('paletteEditorName');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paletteEditorProvider);

    if (state == null) {
      return const NesdScaffold(appBar: NesdAppBar(title: Text('Palette')));
    }

    final editor = ref.read(paletteEditorProvider.notifier);
    final nameController = useTextEditingController(text: state.name);

    return NesdScaffold(
      appBar: NesdAppBar(
        title: const Text('Palette Editor'),
        actions: [
          IconButton(
            key: saveKey,
            icon: const Icon(Icons.save),
            tooltip: 'Save palette',
            onPressed: () => savePalette(context, ref),
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
    );
  }
}
