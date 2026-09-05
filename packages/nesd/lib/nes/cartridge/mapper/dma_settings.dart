class DmaSettings {
  DmaSettings.fromRegister(int value)
    : toPpuData = (value & 0x01) != 0,
      start = value & 0xf0,
      end = ((value & 0xf0) & ~(_lengthOf(value) - 1)) + _lengthOf(value);

  final bool toPpuData;

  final int start;

  final int end;

  static int _lengthOf(int value) {
    return switch ((value >> 1) & 0x07) {
      4 => 16,
      5 => 32,
      6 => 64,
      7 => 128,
      _ => 256,
    };
  }
}
