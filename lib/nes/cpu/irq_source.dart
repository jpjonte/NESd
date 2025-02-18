enum IrqSource {
  apuFrameCounter(1),
  apuDmc(2),
  mapper(4);

  const IrqSource(this.bit);

  final int bit;
}
