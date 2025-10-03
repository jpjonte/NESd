extension StringExtension on String {
  bool containsAny(List<String> values) {
    for (final value in values) {
      if (contains(value)) {
        return true;
      }
    }

    return false;
  }
}

extension NullStringExtension on String? {
  int toIntOrZero() {
    final value = this;

    if (value == null) {
      return 0;
    }

    return int.tryParse(value) ?? 0;
  }
}
