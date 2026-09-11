import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'palette_editor_state.g.dart';

@immutable
class EditSource {
  const EditSource.channel(this.index, this.channel);
  const EditSource.hex(this.index) : channel = -1;
  const EditSource.name() : index = -1, channel = -2;
  const EditSource.reset() : index = -1, channel = -3;

  final int index;
  final int channel;

  @override
  bool operator ==(Object other) =>
      other is EditSource && other.index == index && other.channel == channel;

  @override
  int get hashCode => Object.hash(index, channel);
}

@immutable
class _HistoryEntry {
  const _HistoryEntry({
    required this.name,
    required this.colors,
    required this.source,
  });

  final String name;
  final List<int> colors;

  final EditSource? source;
}

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

  bool get dirty => name != originalName || colorsChanged;

  bool get colorsChanged => !const ListEquality<int>().equals(colors, original);

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

  static const _maxHistory = 100;

  static const _idleBreak = Duration(milliseconds: 700);

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  final List<_HistoryEntry> _history = [];

  int _index = -1;

  EditSource? _openSource;

  DateTime? _lastEditAt;

  bool _dragging = false;

  void open({
    required String name,
    required List<int> colors,
    required bool sourceHadEmphasis,
  }) {
    _history
      ..clear()
      ..add(
        _HistoryEntry(
          name: name,
          colors: colors,
          source: const EditSource.reset(),
        ),
      );

    _index = 0;
    _openSource = null;
    _lastEditAt = null;
    _dragging = false;

    state = PaletteEditorState(
      name: name,
      colors: colors,
      originalName: name,
      original: colors,
      sourceHadEmphasis: sourceHadEmphasis,
    );
  }

  bool get canUndo => _index > 0;

  bool get canRedo => _index < _history.length - 1;

  void select(int index) => _update((s) => s.copyWith(selected: index));

  void setColor(int index, int rgb, {EditSource? source}) =>
      _edit(source, (s) => s.copyWith(colors: [...s.colors]..[index] = rgb));

  void revertColor(int index) => _edit(
    EditSource.hex(index),
    (s) => s.copyWith(colors: [...s.colors]..[index] = s.original[index]),
  );

  void setName(String name) =>
      _edit(const EditSource.name(), (s) => s.copyWith(name: name));

  void resetColors() =>
      _edit(const EditSource.reset(), (s) => s.copyWith(colors: s.original));

  void beginEdit() {
    _dragging = true;
    _openSource = null;
  }

  void endEdit() {
    _dragging = false;
    _openSource = null;
    _lastEditAt = null;
  }

  void undo() => _travel(-1);

  void redo() => _travel(1);

  void markSaved(String name, List<int> colors) =>
      _update((s) => s.copyWith(originalName: name, original: colors));

  void close() => state = null;

  void closeIfMounted() {
    if (!ref.mounted) {
      return;
    }

    close();
  }

  void _edit(
    EditSource? source,
    PaletteEditorState Function(PaletteEditorState) change,
  ) {
    _update(change);

    final current = state;

    if (current == null) {
      return;
    }

    final entry = _HistoryEntry(
      name: current.name,
      colors: current.colors,
      source: source,
    );

    final at = clock();
    final since = _lastEditAt;

    _lastEditAt = at;

    final active =
        _dragging || (since != null && at.difference(since) <= _idleBreak);

    if (source != null && source == _openSource && active && _index >= 0) {
      _history[_index] = entry;

      return;
    }

    _openSource = source;

    _history.removeRange(_index + 1, _history.length);
    _history.add(entry);

    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    _index = _history.length - 1;
  }

  void _travel(int delta) {
    final target = _index + delta;

    if (target < 0 || target >= _history.length) {
      return;
    }

    _index = target;
    _openSource = null;
    _lastEditAt = null;

    final entry = _history[target];

    _update((s) => s.copyWith(name: entry.name, colors: entry.colors));
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
