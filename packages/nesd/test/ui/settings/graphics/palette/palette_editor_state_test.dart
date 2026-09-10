import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/settings/graphics/palette/palette_editor_state.dart';

ProviderContainer _container() {
  final container = ProviderContainer();

  addTearDown(container.dispose);

  return container;
}

List<int> _grey(int value) =>
    List.filled(64, (value << 16) | (value << 8) | value);

void main() {
  test('the editor is closed until it is opened', () {
    final container = _container();

    expect(container.read(paletteEditorProvider), isNull);
    expect(container.read(paletteDraftProvider), isNull);
  });

  test('opening seeds a clean draft', () {
    final container = _container();

    container
        .read(paletteEditorProvider.notifier)
        .open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

    final state = container.read(paletteEditorProvider)!;

    expect(state.name, equals('Mine'));
    expect(state.selected, equals(0));
    expect(state.dirty, isFalse);
    expect(
      container.read(paletteDraftProvider),
      equals(expandRgbToPalette(_grey(0x40))),
    );
  });

  test('changing a colour marks the draft dirty and updates the palette', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setColor(3, 0x102030);

    expect(container.read(paletteEditorProvider)!.dirty, isTrue);
    expect(
      container.read(paletteDraftProvider)![3],
      equals(packPaletteColor(0x10, 0x20, 0x30)),
    );
  });

  test('renaming marks the draft dirty', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setName('Yours');

    expect(container.read(paletteEditorProvider)!.dirty, isTrue);
  });

  test('reverting a colour restores the one it opened with', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setColor(3, 0x102030)
      ..revertColor(3);

    expect(container.read(paletteEditorProvider)!.dirty, isFalse);
  });

  test('markSaved makes the current draft the clean baseline', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setColor(3, 0x102030)
      ..setName('Yours');

    final saved = container.read(paletteEditorProvider)!;

    container
        .read(paletteEditorProvider.notifier)
        .markSaved(saved.name, saved.colors);

    expect(container.read(paletteEditorProvider)!.dirty, isFalse);
  });

  test('markSaved leaves a later edit dirty against the promoted baseline', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setColor(3, 0x102030);

    final saved = container.read(paletteEditorProvider)!;

    container.read(paletteEditorProvider.notifier)
      ..setColor(3, 0x506070)
      ..markSaved(saved.name, saved.colors);

    final state = container.read(paletteEditorProvider)!;

    expect(state.dirty, isTrue);
    expect(state.original[3], equals(0x102030));
    expect(state.colors[3], equals(0x506070));
  });

  test('closing drops the draft', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..close();

    expect(container.read(paletteEditorProvider), isNull);
    expect(container.read(paletteDraftProvider), isNull);
  });

  test('select moves the selected index', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..select(5);

    expect(container.read(paletteEditorProvider)!.selected, equals(5));
  });

  test('picking a swatch keeps the same paletteDraft instance', () {
    final container = _container();

    container
        .read(paletteEditorProvider.notifier)
        .open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

    final before = container.read(paletteDraftProvider);

    container.read(paletteEditorProvider.notifier).select(5);

    final after = container.read(paletteDraftProvider);

    expect(identical(before, after), isTrue);
  });

  test('the draft stays unmodifiable through edits and after saving', () {
    final container = _container();

    container.read(paletteEditorProvider.notifier)
      ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
      ..setColor(3, 0x102030);

    final saved = container.read(paletteEditorProvider)!;

    container
        .read(paletteEditorProvider.notifier)
        .markSaved(saved.name, saved.colors);

    final state = container.read(paletteEditorProvider)!;

    expect(() => state.colors[0] = 0, throwsUnsupportedError);
    expect(() => state.original[0] = 0, throwsUnsupportedError);
  });

  group('history', () {
    test('an edit can be undone and redone', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..setColor(3, 0x102030, source: const EditSource.hex(3));

      expect(container.read(paletteEditorProvider)!.colors[3], 0x102030);

      notifier.undo();

      expect(container.read(paletteEditorProvider)!.colors[3], _grey(0x40)[3]);
      expect(container.read(paletteEditorProvider)!.dirty, isFalse);

      notifier.redo();

      expect(container.read(paletteEditorProvider)!.colors[3], 0x102030);
    });

    test('nothing to undo or redo on a freshly opened draft', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isFalse);

      notifier
        ..undo()
        ..redo();

      expect(container.read(paletteEditorProvider)!.colors, _grey(0x40));
    });

    test('a drag of one channel collapses into a single step', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

      const source = EditSource.channel(3, 0);

      for (var value = 0x41; value <= 0x60; value++) {
        notifier.setColor(3, value << 16, source: source);
      }

      notifier.undo();

      expect(container.read(paletteEditorProvider)!.colors[3], _grey(0x40)[3]);
      expect(notifier.canUndo, isFalse);
    });

    test('editing a different channel starts a new step', () {
      final container = _container();
      container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..setColor(3, 0x110000, source: const EditSource.channel(3, 0))
        ..setColor(3, 0x112200, source: const EditSource.channel(3, 1))
        ..undo();

      expect(container.read(paletteEditorProvider)!.colors[3], 0x110000);
    });

    test('selecting a swatch is not an edit', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..select(5);

      expect(notifier.canUndo, isFalse);
    });

    test('a new edit after undoing drops what was undone', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..setColor(3, 0x110000, source: const EditSource.hex(3))
        ..undo()
        ..setColor(4, 0x220000, source: const EditSource.hex(4));

      expect(notifier.canRedo, isFalse);

      notifier.redo();

      expect(container.read(paletteEditorProvider)!.colors[4], 0x220000);
    });

    test('resetting the colors is a single undoable step', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..setColor(3, 0x110000, source: const EditSource.hex(3))
        ..setColor(4, 0x220000, source: const EditSource.hex(4))
        ..setName('Renamed')
        ..resetColors();

      final reset = container.read(paletteEditorProvider)!;

      expect(reset.colors, _grey(0x40));
      expect(reset.name, equals('Renamed'));

      notifier.undo();

      final restored = container.read(paletteEditorProvider)!;

      expect(restored.colors[3], 0x110000);
      expect(restored.colors[4], 0x220000);
    });

    test('undoing past a save leaves the draft dirty again', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false)
        ..setColor(3, 0x110000, source: const EditSource.hex(3));

      final saved = container.read(paletteEditorProvider)!;

      notifier.markSaved(saved.name, saved.colors);

      expect(container.read(paletteEditorProvider)!.dirty, isFalse);

      notifier.undo();

      final undone = container.read(paletteEditorProvider)!;

      expect(undone.colors[3], _grey(0x40)[3]);
      expect(undone.dirty, isTrue);
      expect(undone.originalName, equals(saved.name));
    });

    test('a pause splits edits from the same control into two steps', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

      var now = DateTime(2026);

      notifier.clock = () => now;

      const source = EditSource.channel(3, 0);

      notifier.setColor(3, 0x200000, source: source);

      now = now.add(const Duration(seconds: 10));

      notifier
        ..setColor(3, 0x800000, source: source)
        ..undo();

      expect(container.read(paletteEditorProvider)!.colors[3], 0x200000);

      notifier.undo();

      expect(container.read(paletteEditorProvider)!.colors[3], _grey(0x40)[3]);
    });

    test('a drag is one step however long it is held', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

      var now = DateTime(2026);

      notifier.clock = () => now;

      const source = EditSource.channel(3, 0);

      notifier.beginEdit();

      for (var value = 0x20; value <= 0x80; value += 0x10) {
        notifier.setColor(3, value << 16, source: source);

        now = now.add(const Duration(seconds: 3));
      }

      notifier
        ..endEdit()
        ..undo();

      expect(container.read(paletteEditorProvider)!.colors[3], _grey(0x40)[3]);
      expect(notifier.canUndo, isFalse);
    });

    test('an edit after a drag ends is its own step', () {
      final container = _container();
      final notifier = container.read(paletteEditorProvider.notifier)
        ..open(name: 'Mine', colors: _grey(0x40), sourceHadEmphasis: false);

      const source = EditSource.channel(3, 0);

      notifier
        ..beginEdit()
        ..setColor(3, 0x200000, source: source)
        ..endEdit()
        ..beginEdit()
        ..setColor(3, 0x800000, source: source)
        ..endEdit()
        ..undo();

      expect(container.read(paletteEditorProvider)!.colors[3], 0x200000);
    });
  });
}
