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
