import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'palette_editor_state.g.dart';

@immutable
class PaletteEditorState {
  PaletteEditorState({
    required this.name,
    required List<int> colors,
    required this.originalName,
    required List<int> original,
    required this.sourceHadEmphasis,
    this.selected = 0,
  }) : colors = _unmodifiable(colors),
       original = _unmodifiable(original);

  final String name;

  final List<int> colors;

  final String originalName;

  final List<int> original;

  final bool sourceHadEmphasis;

  final int selected;

  bool get dirty =>
      name != originalName ||
      !const ListEquality<int>().equals(colors, original);

  int get selectedColor => colors[selected];

  PaletteEditorState copyWith({
    String? name,
    List<int>? colors,
    String? originalName,
    List<int>? original,
    int? selected,
  }) => PaletteEditorState(
    name: name ?? this.name,
    colors: colors ?? this.colors,
    originalName: originalName ?? this.originalName,
    original: original ?? this.original,
    sourceHadEmphasis: sourceHadEmphasis,
    selected: selected ?? this.selected,
  );

  static List<int> _unmodifiable(List<int> list) =>
      list is UnmodifiableListView<int> ? list : UnmodifiableListView(list);
}

@Riverpod(keepAlive: true)
class PaletteEditor extends _$PaletteEditor {
  @override
  PaletteEditorState? build() => null;

  void open({
    required String name,
    required List<int> colors,
    required bool sourceHadEmphasis,
  }) {
    state = PaletteEditorState(
      name: name,
      colors: colors,
      originalName: name,
      original: colors,
      sourceHadEmphasis: sourceHadEmphasis,
    );
  }

  void select(int index) => _update((s) => s.copyWith(selected: index));

  void setColor(int index, int rgb) =>
      _update((s) => s.copyWith(colors: [...s.colors]..[index] = rgb));

  void revertColor(int index) => _update(
    (s) => s.copyWith(colors: [...s.colors]..[index] = s.original[index]),
  );

  void setName(String name) => _update((s) => s.copyWith(name: name));

  void markSaved(String name, List<int> colors) =>
      _update((s) => s.copyWith(originalName: name, original: colors));

  void close() => state = null;

  void closeIfMounted() {
    if (!ref.mounted) {
      return;
    }

    close();
  }

  void _update(PaletteEditorState Function(PaletteEditorState) change) {
    final current = state;

    if (current == null) {
      return;
    }

    state = change(current);
  }
}

@Riverpod(keepAlive: true)
Uint32List? paletteDraft(Ref ref) {
  final colors = ref.watch(
    paletteEditorProvider.select((state) => state?.colors),
  );

  if (colors == null) {
    return null;
  }

  return expandRgbToPalette(colors);
}
