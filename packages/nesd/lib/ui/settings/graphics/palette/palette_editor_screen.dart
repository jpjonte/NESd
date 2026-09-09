import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';

@RoutePage()
class PaletteEditorScreen extends ConsumerWidget {
  const PaletteEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paletteEditorProvider);

    if (state == null) {
      return const NesdScaffold(appBar: NesdAppBar(title: Text('Palette')));
    }

    final editor = ref.read(paletteEditorProvider.notifier);

    return NesdScaffold(
      appBar: const NesdAppBar(title: Text('Palette Editor')),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                children: [grid, const SizedBox(height: 16), controls],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: grid),
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
