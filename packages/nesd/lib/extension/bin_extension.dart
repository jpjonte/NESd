extension BinExtension on int {
  String toBin([int width = 8]) {
    return toRadixString(2).padLeft(width, '0').toUpperCase();
  }
}
