enum IrqSource {
  apuFrameCounter(1),
  apuDmc(2),
  mapper(4),
  mapperAudio(8);

  const IrqSource(this.value);

  final int value;
}
