extension HexExtension on int {
  String toHex({int width = 2, bool prefix = false, bool upperCase = true}) {
    final value = toRadixString(16).padLeft(width, '0');
    final cased = upperCase ? value.toUpperCase() : value;

    return prefix ? '0x$cased' : cased;
  }
}
