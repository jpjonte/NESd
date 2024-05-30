extension HexExtension on int {
  String toHex([int width = 2]) {
    return toRadixString(16).padLeft(width, '0').toUpperCase();
  }
}
