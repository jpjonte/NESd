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
}
