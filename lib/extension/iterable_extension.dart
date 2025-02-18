// catching the error is intentional
// ignore_for_file: avoid_catching_errors

extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    try {
      return firstWhere(test);
    } on StateError {
      return null;
    }
  }
}
