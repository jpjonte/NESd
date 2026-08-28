enum FastForwardSpeed {
  x2(2),
  x3(3),
  x4(4),
  max(null);

  const FastForwardSpeed(this.factor);

  final int? factor;
}
