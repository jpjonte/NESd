import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaletteSwatchGrid(
              colors: state.colors,
              selected: state.selected,
              onSelected: editor.select,
            ),
          ],
        ),
      ),
    );
  }
}
