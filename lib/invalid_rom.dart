class InvalidRom implements Exception {
  final String message;
  final Exception? previous;

  InvalidRom(this.message, {this.previous});

  @override
  String toString() => message;
}
