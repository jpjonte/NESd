import 'package:flutter/foundation.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';

@immutable
sealed class PaletteSelection {
  const PaletteSelection();

  static const PaletteSelection defaultSelection = BuiltInPaletteSelection(
    NesPaletteId.defaultPalette,
  );

  PaletteSelection effective(Iterable<String> loaded) => switch (this) {
    UserPaletteSelection(:final name) when !loaded.contains(name) =>
      defaultSelection,
    _ => this,
  };
}

@immutable
class BuiltInPaletteSelection extends PaletteSelection {
  const BuiltInPaletteSelection(this.id)
    : assert(id != NesPaletteId.user, 'user palettes are selected by name');

  final NesPaletteId id;

  @override
  bool operator ==(Object other) =>
      other is BuiltInPaletteSelection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class UserPaletteSelection extends PaletteSelection {
  const UserPaletteSelection(this.name);

  final String name;

  @override
  bool operator ==(Object other) =>
      other is UserPaletteSelection && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
