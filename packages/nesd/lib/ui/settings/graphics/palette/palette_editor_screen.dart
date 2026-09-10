import 'dart:async';
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/common/confirmation_dialog.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/common/nesd_app_bar.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/common/settings_tile.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_actions.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_color_editor.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_frame_preview.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_save_action.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_swatch_grid.dart';
import 'package:nesd/ui/toast/toaster.dart';

@RoutePage()
class PaletteEditorScreen extends HookConsumerWidget {
  const PaletteEditorScreen({super.key});

  static const saveKey = Key('paletteEditorSave');

  static const exportKey = Key('paletteEditorExport');

  static const nameKey = Key('paletteEditorName');

  static const emphasisWarningKey = Key('paletteEmphasisWarning');

  static const undoKey = Key('paletteEditorUndo');

  static const redoKey = Key('paletteEditorRedo');

  static const resetKey = Key('paletteEditorReset');

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

    // Above the screen, so a focused text field keeps its own undo: its
    // shortcuts are handled closer to the field and win.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: _HistoryAction<_UndoIntent>(editor.undo),
          _RedoIntent: _HistoryAction<_RedoIntent>(editor.redo),
        },
        child: _buildScreen(context, ref, state, editor, nameController),
      ),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    PaletteEditorState state,
    PaletteEditor editor,
    TextEditingController nameController,
  ) {
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
              key: undoKey,
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: editor.canUndo ? editor.undo : null,
            ),
            IconButton(
              key: redoKey,
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: editor.canRedo ? editor.redo : null,
            ),
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
            final controls = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaletteColorEditor(state: state),
                FocusOnHover(
                  child: ButtonSettingsTile(
                    key: resetKey,
                    title: const Text('Reset all colors'),
                    onPressed: state.colorsChanged ? editor.resetColors : null,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 600) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nameField,
                    const SizedBox(height: 16),
                    if (state.sourceHadEmphasis)
                      const _EmphasisWarning(key: emphasisWarningKey),
                    const PaletteFramePreview(),
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
                      children: [
                        nameField,
                        const SizedBox(height: 16),
                        if (state.sourceHadEmphasis)
                          const _EmphasisWarning(key: emphasisWarningKey),
                        grid,
                        const SizedBox(height: 16),
                        const Expanded(child: PaletteFramePreview()),
                      ],
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

class _EmphasisWarning extends StatelessWidget {
  const _EmphasisWarning({required super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This palette has its own emphasis colors. Saving '
              'replaces them with generated ones.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryAction<T extends Intent> extends Action<T> {
  _HistoryAction(this.step);

  final void Function() step;

  @override
  bool isEnabled(T intent) => !_editingText();

  @override
  void invoke(T intent) => step();

  static bool _editingText() {
    final context = FocusManager.instance.primaryFocus?.context;

    if (context == null) {
      return false;
    }

    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
