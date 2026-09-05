import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';

void main() {
  test('built-in selections compare by id', () {
    expect(
      const BuiltInPaletteSelection(NesPaletteId.warm),
      equals(const BuiltInPaletteSelection(NesPaletteId.warm)),
    );
    expect(
      const BuiltInPaletteSelection(NesPaletteId.warm),
      isNot(equals(const BuiltInPaletteSelection(NesPaletteId.cool))),
    );
  });

  test('a built-in selection rejects the user id', () {
    expect(
      () => BuiltInPaletteSelection(NesPaletteId.user),
      throwsAssertionError,
    );
  });

  test('user selections compare by name', () {
    expect(
      const UserPaletteSelection('Foo'),
      equals(const UserPaletteSelection('Foo')),
    );
    expect(
      const UserPaletteSelection('Foo'),
      isNot(equals(const UserPaletteSelection('Bar'))),
    );
  });

  test('a built-in and a user selection never compare equal', () {
    expect(
      const BuiltInPaletteSelection(NesPaletteId.defaultPalette),
      isNot(equals(const UserPaletteSelection('Default'))),
    );
  });

  test('equal selections share a hash code', () {
    expect(
      const UserPaletteSelection('Foo').hashCode,
      equals(const UserPaletteSelection('Foo').hashCode),
    );
    expect(
      const BuiltInPaletteSelection(NesPaletteId.flat).hashCode,
      equals(const BuiltInPaletteSelection(NesPaletteId.flat).hashCode),
    );
  });

  test('defaultSelection is the built-in default palette', () {
    expect(
      PaletteSelection.defaultSelection,
      equals(const BuiltInPaletteSelection(NesPaletteId.defaultPalette)),
    );
  });

  group('effective', () {
    test('keeps built-ins regardless of what is loaded', () {
      const selection = BuiltInPaletteSelection(NesPaletteId.warm);

      expect(selection.effective(const []), equals(selection));
    });

    test('keeps a user palette that is loaded', () {
      const selection = UserPaletteSelection('Foo');

      expect(selection.effective(const ['Foo', 'Bar']), equals(selection));
    });

    test('falls back to the default for a user palette that is not', () {
      const selection = UserPaletteSelection('Foo');

      expect(
        selection.effective(const ['Bar']),
        equals(PaletteSelection.defaultSelection),
      );
    });
  });
}
