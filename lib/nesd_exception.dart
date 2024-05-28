class NesdException implements Exception {
  NesdException(this.message, {this.previous});

  final String message;
  final Exception? previous;

  @override
  String toString() => message;
}
